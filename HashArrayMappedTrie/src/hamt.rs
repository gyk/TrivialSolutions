
//! # Hash Array Mapped Trie
//!
//! Just a fake HAMT implementation, solely for learning purpose (I call it fake because there is no
//! way to share the nodes, let alone making the tree persistent).
//!
//! # References
//!
//! - Bagwell, Phil. Ideal hash trees. No. LAMP-REPORT-2001-001. 2001.
//! - https://worace.works/2016/05/24/hash-array-mapped-tries/
//! - https://github.com/sile/cc-hamt
//! - https://github.com/rainbowbismuth/hamt-rs
//! - https://github.com/ezyang/hamt
//!

// TODO: make nodes sharable
// TODO: root entries

use std::mem;

type Bitmap = u32;

// number of bits per AMT node
const BITS_PER_AMT: usize = 5;

fn get_sub_hkey(hkey: u32, shift: usize) -> u32 {
    (hkey >> shift) & ((1 << BITS_PER_AMT) - 1)
}


#[derive(Default)]
struct Node<K, V> {
    entries: Vec<Entry<K, V>>,
    bitmap: Bitmap,
}

impl<K: Eq, V> Node<K, V> {
    pub fn is_valid_entry(&self, index: usize) -> bool {
        (self.bitmap >> index) & 1 != 0
    }

    pub fn entry_index(&self, index: usize) -> usize {
        (self.bitmap & ((1 << index) - 1)).count_ones() as usize
    }

    pub fn get_entry(&self, index: usize) -> Option<&Entry<K, V>> {
        if !self.is_valid_entry(index) {
            None
        } else {
            let map_idx = self.entry_index(index);
            debug_assert!(map_idx < self.entries.len(), "Index exceeds the length of `entries`");
            self.entries.get(map_idx)
        }
    }

    pub fn get_or_insert_entry(&mut self, index: usize) -> &mut Entry<K, V> {
        if !self.is_valid_entry(index) {
            let new_map_idx = self.entry_index(index);
            self.entries.push(Entry::Null);

            let mut i = self.entries.len() - 1;
            while i > new_map_idx {
                self.entries.swap(i, i - 1);
                i -= 1;
            }
            self.bitmap |= 1 << index;
            &mut self.entries[new_map_idx]
        } else {
            debug_assert!(index < self.entries.len(), "Index exceeds the length of `entries`");
            let map_idx = self.entry_index(index);
            &mut self.entries[map_idx]
        }
    }
}

struct Leaf<K, V> {
    key: K,
    value: V,
}

// In the style of really low-level programming, this struct can be made more compact relying on the
// fact that an allocated value is aligned so the least-significant bit can be used to indicate
// whether it is a node or leaf.
//
// For supporting persistent tree, `Box` must be changed to `Arc`.
enum Entry<K, V> {
    Null,
    Leaf(Box<Leaf<K, V>>),
    Node(Box<Node<K, V>>),
}

pub struct Hamt<K, V, F> {
    root: Entry<K, V>,
    hash: F,
    count: usize,
}

impl<K, V, F> Hamt<K, V, F>
    where K: Eq, F: Fn(&K) -> u32
{
    pub fn new(hash: F) -> Hamt<K, V, F> {
        Hamt {
            root: Entry::Null,
            hash: hash,
            count: 0,
        }
    }

    pub fn get(&self, key: &K) -> Option<&V> {
        let hkey = (self.hash)(key);
        let mut entry = &self.root;
        let mut shift = 0;
        loop {
            match *entry {
                Entry::Null => {
                    return None;
                }
                Entry::Leaf(ref leaf) => {
                    if leaf.key == *key {
                        return Some(&leaf.value);
                    } else {
                        return None;
                    }
                }
                Entry::Node(ref node) => {
                    let sub_hkey = get_sub_hkey(hkey, shift);
                    shift += BITS_PER_AMT;

                    match node.get_entry(sub_hkey as usize) {
                        Some(ent) => entry = ent,
                        None => return None,
                    }
                }
            }
        }
    }

    pub fn insert(&mut self, key: K, value: V) -> Option<V> {
        let hkey = (self.hash)(&key);
        let mut entry = &mut self.root;
        let mut shift = 0;
        loop {
            match *entry {
                Entry::Null => {
                    *entry = Entry::Leaf(
                        Box::new(Leaf {
                            key,
                            value,
                        })
                    );
                    self.count += 1;
                    return None;
                }

                Entry::Leaf(..) => {
                    let mut entry_taken = mem::replace(entry, Entry::Null);
                    if let Entry::Leaf(mut leaf) = entry_taken {
                        if leaf.key == key {
                            *entry = Entry::Leaf(
                                Box::new(Leaf {
                                    key: key,
                                    value: value,
                                })
                            );
                            return Some(leaf.value);
                        } else {
                            let new_entry = Entry::Leaf(
                                Box::new(Leaf {
                                    key,
                                    value,
                                })
                            );

                            let next_sub_hkey = get_sub_hkey(hkey, shift);

                            let old_hkey = (self.hash)(&leaf.key);
                            let old_sub_hkey = get_sub_hkey(old_hkey, shift);
                            let old_entry = Entry::Leaf(leaf);

                            let entries = if old_sub_hkey < next_sub_hkey {
                                vec![old_entry, new_entry]
                            } else {
                                vec![new_entry, old_entry]
                            };

                            let node = Box::new(Node {
                                entries: entries,
                                bitmap: (1 << old_sub_hkey) | (1 << next_sub_hkey),
                            });

                            *entry = Entry::Node(node);
                            self.count += 1;
                            return None;
                        }
                    } else {
                        unreachable!();
                    }
                }

                Entry::Node(..) => {
                    // The borrow checker is not smart enough, so without introducing a new variable
                    // name, it complains about "mutable borrow starts here in previous iteration of
                    // loop".
                    let entry2 = entry;
                    let next_entry = match *entry2 {
                        Entry::Node(ref mut node) => {
                            let sub_hkey = get_sub_hkey(hkey, shift);
                            shift += BITS_PER_AMT;
                            node.get_or_insert_entry(sub_hkey as usize)
                        }
                        _ => unreachable!(),
                    };

                    entry = next_entry;
                }
            }
        }
    }

    #[allow(unused_variables)]
    pub fn remove(&mut self, key: &K) -> Option<V> {
        unimplemented!();
    }

    pub fn len(&self) -> usize {
        self.count
    }
}
