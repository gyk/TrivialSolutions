//! Cuckoo Hashing

use std::hash::{Hash, Hasher};
use std::mem;

use rand::{thread_rng, Rng};
use siphasher::sip::SipHasher;

const DEFAULT_CAPACITY: usize = 1024;

struct KeyValue<K, V> {
    key: K,
    value: V,
}

impl<K, V> KeyValue<K, V> {
    fn new(key: K, value: V) -> Self {
        Self {
            key,
            value,
        }
    }

    fn replace(&mut self, new_value: V) -> V {
        mem::replace(&mut self.value, new_value)
    }
}

fn hash_by<K: Hash>(key: &K, (k0, k1): (u64, u64)) -> u64 {
    let mut hasher = SipHasher::new_with_keys(k0, k1);
    key.hash(&mut hasher);
    hasher.finish()
}

pub struct CuckooHashMap<K, V> {
    seeds: [(u64, u64); 2],
    tables: [Vec<Option<KeyValue<K, V>>>; 2], // overhead of Option?
    cycle_threshold: usize,
    n_elements: usize,
}

impl<K: Hash + Eq, V: Clone> CuckooHashMap<K, V> {
    pub fn new() -> Self {
        Self::with_capacity(DEFAULT_CAPACITY)
    }

    /// Capacity refers to the length of both allocated vectors.
    pub fn with_capacity(cap: usize) -> Self {
        assert!(cap > 1, "Capacity too small");
        let mut this = CuckooHashMap {
            seeds: Default::default(),
            tables: [
                vec![],
                vec![],
            ],
            cycle_threshold: (cap as f64).log2().ceil() as usize,
            n_elements: 0,
        };
        for t in 0 ..= 1 {
            this.tables[t] = (0..cap).map(|_| None).collect();
        }
        this.reseed();
        this
    }

    pub fn capacity(&self) -> usize {
        self.tables[0].len()
    }

    pub fn len(&self) -> usize {
        self.n_elements
    }

    fn key_to_i(&self, key: &K, t: usize) -> usize {
        (hash_by(&key, self.seeds[t]) as usize) % self.capacity()
    }

    fn get_kv_at(&self, key: &K, t: usize) -> Option<&KeyValue<K, V>> {
        let i = self.key_to_i(&key, t);
        match &self.tables[t][i] {
            Some(kv) if &kv.key == key => Some(&kv),
            _ => None,
        }
    }

    fn get_kv_at_mut(&mut self, key: &K, t: usize) -> Option<&mut KeyValue<K, V>> {
        let i = self.key_to_i(&key, t);
        match &mut self.tables[t][i] {
            Some(kv) if &kv.key == key => Some(kv),
            _ => None,
        }
    }

    pub fn insert(&mut self, key: K, value: V) -> Option<V> {
        // TODO: Should resize when loading factor exceeds a particular value. The cuckoo hashmap
        // cannot function when it is almost full.
        if self.len() == self.capacity() * 2 {
            panic!("The hashmap is full");
        }

        match self.get_kv_at_mut(&key, 0) {
            Some(kv) => {
                return Some(kv.replace(value));
            }
            None => (),
        }

        let mut kv = KeyValue::new(key, value);
        self.n_elements += 1;
        loop {
            kv = match self.cuckoo(kv, 0) {
                None => return None,
                Some(kv) => {
                    self.rehash();
                    kv
                }
            };
        }
    }

    // If the iteration does not end after the threshold, returns the KV passed in the arguments. If
    // the insersion succeeds, returns `None`.
    fn cuckoo(&mut self, kv: KeyValue<K, V>, mut t: usize)
        -> Option<KeyValue<K, V>>
    {
        match self.cuckoo_impl(kv, &mut t, self.cycle_threshold) {
            None => None,
            Some(kv) => {
                t = 1 - t;
                // puts it back in reversed order
                self.cuckoo_impl(kv, &mut t, self.cycle_threshold)
            }
        }
    }

    // The cuckoo insert version specifically for rehashing. The cycle threshold is set to the
    // number of elements in the table.
    fn cuckoo_rehash(&mut self, kv: KeyValue<K, V>, mut t: usize)
        -> Option<KeyValue<K, V>>
    {
        self.cuckoo_impl(kv, &mut t, self.len())
    }

    // Returns the last KV.
    fn cuckoo_impl(&mut self, mut kv: KeyValue<K, V>, t: &mut usize, cycle_threshold: usize)
        -> Option<KeyValue<K, V>>
    {
        let mut n_loops = cycle_threshold;
        while n_loops > 0 {
            let i = self.key_to_i(&kv.key, *t);
            match self.tables[*t][i].as_mut() {
                None => {
                    self.tables[*t][i] = Some(kv);
                    return None;
                }
                Some(old_kv) => {
                    kv = mem::replace(old_kv, kv);
                    *t = 1 - *t;
                }
            }
            n_loops -= 1;
        }
        Some(kv)
    }

    fn reseed(&mut self) {
        let mut rng = thread_rng();
        self.seeds[0] = rng.gen();
        self.seeds[1] = loop {
            let s = rng.gen();
            if s != self.seeds[0] {
                break s;
            }
        };
    }

    fn remove_at(&mut self, t: usize, i: usize) -> Option<KeyValue<K, V>> {
        mem::replace(&mut self.tables[t][i], None)
    }

    // In-place rehash
    fn rehash(&mut self) {
        while !self.rehash_impl() {} // FIXME: resizes if repeatedly failed
    }

    fn find_vacancy(&mut self) -> &mut Option<KeyValue<K, V>> {
        for t in 0 ..= 1 {
            for i in 0..self.capacity() {
                if self.tables[t][i].is_none() {
                    return &mut self.tables[t][i];
                }
            }
        }
        unreachable!("At least one vacant should exist");
    }

    fn rehash_impl(&mut self) -> bool {
        self.reseed();

        for t in 0 ..= 1 {
            for i in 0..self.capacity() {
                if let Some(kv) = &self.tables[t][i] {
                    let key = &kv.key;
                    if self.key_to_i(key, t) != i { // misplaced
                        let kv = self.remove_at(t, i).unwrap();
                        if let Some(kv) = self.cuckoo_rehash(kv, t) {
                            *self.find_vacancy() = Some(kv); // puts it back
                            return false;
                        }
                    }
                }
            }
        }
        true
    }

    pub fn get(&self, key: &K) -> Option<&V> {
        for t in 0 ..= 1 {
            match self.get_kv_at(key, t) {
                Some(kv) => return Some(&kv.value),
                None => (),
            }
        }
        None
    }

    pub fn get_mut(&mut self, key: &K) -> Option<&mut V> {
        // Cannot simply call `get_kv_at_mut` inside the loop, because of
        // https://github.com/rust-lang/rust/issues/21906.
        for t in 0 ..= 1 {
            let i = self.key_to_i(&key, t);
            if self.tables[t][i].is_some() {
                return self.tables[t][i].as_mut().map(|kv| &mut kv.value);
            }
        }
        None
    }

    pub fn contains(&self, key: &K) -> bool {
        self.get(key).is_some()
    }

    pub fn remove(&mut self, key: &K) -> Option<V> {
        for t in 0 ..= 1 {
            let i = self.key_to_i(&key, t);
            match &mut self.tables[t][i] {
                Some(kv) if &kv.key == key => {
                    let kv = self.tables[t][i].take().unwrap();
                    self.n_elements -= 1;
                    return Some(kv.value);
                }
                _ => (),
            }
        }
        None
    }
}


#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn smoke() {
        let mut cuckoo_hashmap = CuckooHashMap::with_capacity(1000);
        for k in 0..500 {
            assert_eq!(cuckoo_hashmap.insert(k, 1), None);
        }

        for k in 0..500 {
            assert!(cuckoo_hashmap.contains(&k));
        }
        assert_eq!(cuckoo_hashmap.len(), 500);

        for k in 0..250 {
            assert_eq!(cuckoo_hashmap.remove(&k), Some(1));
        }
        assert_eq!(cuckoo_hashmap.len(), 250);

        for k in 0..250 {
            assert!(!cuckoo_hashmap.contains(&k));
        }

        for k in 250..500 {
            assert!(cuckoo_hashmap.contains(&k));
        }
    }

    #[test]
    fn rehash() {
        let mut cuckoo_hashmap;
        loop {
            cuckoo_hashmap = CuckooHashMap::with_capacity(500);
            let old_seeds = cuckoo_hashmap.seeds;
            for k in 0..500 {
                assert_eq!(cuckoo_hashmap.insert(k, 1), None);
            }
            if cuckoo_hashmap.seeds != old_seeds {
                println!("Rehash occurred");
                break;
            } else {
                continue;
            }
        }
        assert_eq!(cuckoo_hashmap.len(), 500);
        for k in 0..500 {
            assert!(cuckoo_hashmap.contains(&k));
        }
    }
}
