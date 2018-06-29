pub mod hamt;

pub use hamt::*;

#[cfg(test)]
mod tests {
    use super::*;

    use std::hash::{Hash, Hasher};
    use std::collections::hash_map::DefaultHasher;

    fn hash(s: &String) -> u32 {
        let mut hasher = DefaultHasher::new();
        s.hash(&mut hasher);
        let h = hasher.finish();
        // FIXME?
        ((h >> 32) as u32) ^ (h as u32)
    }

    #[test]
    fn smoke() {
        let mut hamt = Hamt::new(hash);
        hamt.insert("Hello".to_owned(), 100);
        hamt.insert("Rust".to_owned(), 26);
        hamt.insert("World!".to_owned(), 42);

        println!("len = {}", hamt.len());
        println!("{:?}", hamt.get(&"Hello".to_owned()));
        println!("{:?}", hamt.get(&"C++".to_owned()));
        println!("{:?}", hamt.get(&"World!".to_owned()));
    }

    // TODO: quickcheck
}
