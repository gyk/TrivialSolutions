use std::cmp::{self, Ordering};
use std::ops::Index;

#[derive(Debug, Clone)]
pub(crate) struct WrapStr<'a, T: 'static> {
    s: &'a [T],
    pub start_index: usize,
}

impl<'a, T> WrapStr<'a, T> {
    pub fn new(s: &'a [T], start_index: usize) -> Self {
        WrapStr {
            s,
            start_index,
        }
    }

    #[inline]
    pub fn len(&self) -> usize {
        self.s.len()
    }
}

impl<'a, T> Index<usize> for WrapStr<'a, T> {
    type Output = T;

    fn index(&self, i: usize) -> &Self::Output {
        let mut idx = self.start_index + i;
        idx = idx % self.len();
        &self.s[idx]
    }
}

impl<'a, T: Ord> PartialOrd for WrapStr<'a, T> {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}

impl<'a, T: Ord> Ord for WrapStr<'a, T> {
    fn cmp(&self, other: &Self) -> Ordering {
        let max_l = cmp::max(self.len(), other.len());
        let min_l = cmp::min(self.len(), other.len());

        for i in 0..max_l {
            match self[i].cmp(&other[i]) {
                Ordering::Equal => (),
                non_eq => return non_eq,
            }
        }

        // If reaching here, let the shorter sequence be `A`, then the longer one must be `A + A * k
        // + A[max_l % min_l ..]`, so we have `A == rotate(A, max_l % min_l)`.
        let extra_l = match max_l % min_l {
            0 => 0,
            l => min_l - l,
        };
        for i in max_l .. max_l + extra_l {
            match self[i].cmp(&other[i]) {
                Ordering::Equal => (),
                non_eq => return non_eq,
            }
        }
        Ordering::Equal
    }
}

impl<'a, T: Ord> PartialEq for WrapStr<'a, T> {
    fn eq(&self, other: &Self) -> bool {
        self.cmp(other) == Ordering::Equal
    }
}

impl<'a, T: Ord> Eq for WrapStr<'a, T> {}

use std::fmt;

// For simplcity, uses `T: fmt::Debug` rather than `T: fmt::Display`.
impl<'a, T: fmt::Debug> fmt::Display for WrapStr<'a, T> {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        f.debug_list().entries((0 .. self.len()).map(|i| &self[i])).finish()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn wrap_str_rotate() {
        const ALPHABET: &[u8] = b"abcdefg";

        let mut rotated = (0..ALPHABET.len())
            .map(|i| WrapStr::new(ALPHABET, i))
            .collect::<Vec<_>>();
        let rotated_copy = rotated.clone();
        rotated.sort();

        assert_eq!(rotated, rotated_copy);
    }

    #[test]
    #[allow(non_snake_case)]
    fn wrap_str_different_len() {
        let RARE: &[u8] = b"covfefe";
        let RARER: &[u8] = &RARE[3..];
        let RAREST: &[u8] = &RARER[2..];

        let rare = WrapStr::new(RARE, 3);
        let rarer = WrapStr::new(RARER, 0);
        let rarest = WrapStr::new(RAREST, 0);

        assert!(rare < rarer);
        assert!(rare < rarest);
        assert!(rarer == rarest);
    }

    #[test]
    fn wrap_str_fmt() {
        let text: &[u8] = &[1, 2, 3, 4, 5];
        let ws = WrapStr::new(text, 3);
        assert_eq!(&format!("{}", ws), "[4, 5, 1, 2, 3]");
    }
}
