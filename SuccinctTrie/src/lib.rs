//! Succinct Trie
//! =============
//!
//! A succinct trie in Rust. It can only be used as a HashSet rather than a HashMap, because the
//! "value" part is not implemented (but it's trivial to do).
//!
//! **NOTE**: The current code is very inefficient. A well-written succinct trie should support O(1)
//! `rank` query and O(log(n)) `select` query. And the `bit_vec` does not properly handle trailing
//! "0"s, which is buggy.
//!
//! (Some thoughts: If the penalty of cache miss can be totally eliminated, will succinct data
//! structures have any practical use? Anyway, the information-theoretical lower bound of bits is
//! commonly much smaller than the actually data, so who will care much about extra space?)
//!
//! ## Reference
//!
//! - Succinct Data Structures: Cramming 80,000 words into a Javascript file,
//!   http://stevehanov.ca/blog/index.php?id=120
//!

#[macro_use] extern crate lazy_static;

#[cfg(test)]
#[macro_use]
extern crate quickcheck;

pub mod trie;
pub mod bitquery;
pub mod bitwriter;
