use std::collections::{HashMap, VecDeque};
use std::fmt::Debug;
use std::hash::Hash;

// Maybe I should use BitVec and BitWriter libraries published on Crates.io instead of rolling my
// own?
use bitquery::*;
use bitwriter::BitWriter;

pub trait H: Debug + Eq + Hash {}
impl<T: Debug + Eq + Hash> H for T {}

fn moving<T>(t: T) -> T { t }

#[derive(Debug, PartialEq)]
pub struct TrieNode<T: H> {
    children: HashMap<T, TrieNode<T>>,
}

impl<T: H> TrieNode<T> {
    pub fn new() -> Self {
        Self {
            children: HashMap::new(),
        }
    }
}

#[derive(Debug)]
pub struct SuccinctTrie<T: H> {
    root: TrieNode<T>,
}

impl<T: H> SuccinctTrie<T> {
    pub fn new() -> Self {
        Self {
            root: TrieNode::new(),
        }
    }

    pub fn insert(&mut self, string: Vec<T>) {
        let mut node = &mut self.root;
        for chr in string.into_iter() {
            node = moving(node)
                .children
                .entry(chr)
                .or_insert(TrieNode::new());
        }
    }

    /// Encodes nodes in level order. The encoding is a "1" for each child, plus a "0".
    pub fn encode(self) -> (Vec<T>, Vec<u8>) {
        let mut char_vec = Vec::new();
        let bit_vec = Vec::new();
        let mut bwr = BitWriter::new(bit_vec);
        let mut queue = VecDeque::new();
        queue.push_back(self.root);

        while !queue.is_empty() {
            let node = queue.pop_front().expect("never returns `None`");
            bwr.write_n(true, node.children.len()).unwrap();
            bwr.write(false).unwrap();
            for (chr, node) in node.children.into_iter() {
                char_vec.push(chr);
                queue.push_back(node);
            }
        }

        bwr.flush_leftover().unwrap();
        let bit_vec = bwr.writer();
        (char_vec, bit_vec)
    }

    pub fn frozen(self) -> FrozenTrie<T> {
        let (char_vec, bit_vec) = self.encode();
        FrozenTrie::new(char_vec, bit_vec)
    }
}

pub struct FrozenTrie<T: H> {
    char_vec: Vec<T>,
    bit_vec: Vec<u8>,
}

impl<T: H> FrozenTrie<T> {
    pub fn new(char_vec: Vec<T>, bit_vec: Vec<u8>) -> Self {
        Self {
            char_vec,
            bit_vec,
        }
    }

    pub fn contains_key(&self, string: &[T]) -> bool {
        let mut i_node = 0;
        for chr in string {
            let (fst, lst) = self.get_children(i_node).unwrap();
            match (fst ..= lst).find(|&i| &self.char_vec[i - 1] == chr) {
                Some(i) => i_node = i,
                None => return false,
            }

        }
        let (fst, lst) = self.get_children(i_node).unwrap();
        fst > lst // is leaf
    }

    /// Gets the children of node at given `index`.
    ///
    /// Returns a tuple of indices, the 1st of which is the index of its first children, and the 2nd
    /// of which is its last children.
    pub fn get_children(&self, index: usize) -> Option<(usize, usize)> {
        // It is computed by
        //
        //     select(false,    // for 0s
        //         index
        //         - 1          // its first child follows the last node
        //         + 1)         // 0-based to 1-based
        //         - index      // the number of 0s
        //         + 1          // the root
        //         + 1;         // the next one
        let fst = match self.select(false, index) {
            Select::Underflow => 1,
            Select::Position(p) => p - index + 2,
            Select::Overflow => return None,
        };
        let lst = match self.select(false, index + 1) {
            Select::Underflow |
            Select::Overflow => unreachable!(),

            Select::Position(p) => p - (index + 1) + 2 - 1,
        };
        Some((fst, lst))
    }

    #[inline]
    fn rank(&self, is_one: bool, x: usize) -> usize {
        rank(&self.bit_vec, is_one, x)
    }

    #[inline]
    fn select(&self, is_one: bool, x: usize) -> Select {
        select(&self.bit_vec, is_one, x)
    }
}


#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn construct_tree() {
        let words: &[&[u8]] = &[b"hat", b"is", b"it", b"a"];
        let mut t = SuccinctTrie::new();
        for &w in words {
            t.insert(w.to_owned());
        }
        let (char_vec, bit_vec) = t.encode();
        println!("{:?}", char_vec);
        println!("{:?}", bit_vec);
        assert!(true);
    }

    #[test]
    fn get_children() {
        let char_vec: Vec<u8> = vec![];
        let bit_vec = vec![0b1011_1010, 0b1100_1000, 0b0000_0000];
        let ft = FrozenTrie::new(char_vec, bit_vec);
        assert_eq!(ft.get_children(0), Some((1, 1)));
        assert_eq!(ft.get_children(2), Some((5, 5)));
        assert_eq!(ft.get_children(3), Some((6, 7)));
        assert_eq!(ft.get_children(8), Some((9, 8)));
    }

    #[test]
    fn smoke() {
        let mut trie = SuccinctTrie::new();
        let vocabulary: &[&[u8]] = &[
            b"apple",
            b"orange",
            b"alpha",
            b"lamp",
            b"hello",
            b"jello",
            b"quiz",
        ];

        for &word in vocabulary {
            trie.insert(word.to_owned());
        }

        let frozen_trie = trie.frozen();
        for &word in vocabulary {
            assert!(frozen_trie.contains_key(word));
        }
        assert!(!frozen_trie.contains_key(b""));
        assert!(!frozen_trie.contains_key(b"a"));
        assert!(!frozen_trie.contains_key(b"appl"));
        assert!(!frozen_trie.contains_key(b"apples"));
        assert!(!frozen_trie.contains_key(b"hell"));
        assert!(!frozen_trie.contains_key(b"hello!"));
        assert!(!frozen_trie.contains_key(b"nothing"));
    }
}
