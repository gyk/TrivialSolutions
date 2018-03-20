//! Suffix Array, a simplified implementation
//!
//! # Reference:
//!
//! _Algorithms, 4th Edition_ by Robert Sedgewick and Kevin Wayn
//!


pub struct SuffixArray<'a, T: 'static> {
    pub text: &'a [T],
    len: usize,
    suffixes: Vec<&'a [T]>,
}

impl<'a, T: Ord> SuffixArray<'a, T> {
    pub fn new(text: &'a [T]) -> SuffixArray<'a, T> {
        let len = text.len();
        let mut suffixes = Vec::with_capacity(len);
        for i in 0..len {
            suffixes.push(&text[i..]);
        }
        suffixes.sort();

        SuffixArray {
            text,
            len,
            suffixes,
        }
    }

    pub fn len(&self) -> usize {
        self.len
    }

    /// Returns the _i_th smallest suffix.
    pub fn select(&self, i: usize) -> Option<&'a [T]> {
        self.suffixes.get(i).map(|x| *x)
    }

    /// Returns the original index of `i` before sorting (The full text has an original index of 0).
    pub fn original_index(&self, i: usize) -> Option<usize> {
        match self.suffixes.get(i) {
            Some(suffix) => Some(self.len - suffix.len()),
            None => None,
        }
    }

    /// Returns the length of the longest common prefix of the _i_th smallest suffix and the _i_-1st
    /// smallest suffix.
    pub fn longest_common_prefix_len(&self, i: usize) -> Option<usize> {
        if let (Some(s_prev), Some(s)) = (self.suffixes.get(i - 1), self.suffixes.get(i)) {
            Some(Self::common_prefix_len(s_prev, s))
        } else {
            None
        }
    }

    #[inline]
    pub(crate) fn common_prefix_len(a: &[T], b: &[T]) -> usize {
        a.iter()
         .zip(b.iter())
         .map(|(x, y)| x == y)
         .take_while(|b| *b)
         .count()
    }

    /// Returns the number of suffixes strictly less than the `query` string.
    pub fn rank(&self, query: &[T]) -> usize {
        match self.suffixes.binary_search(&query) {
            Ok(i) => i,
            Err(i) => i,
        }
    }
}
