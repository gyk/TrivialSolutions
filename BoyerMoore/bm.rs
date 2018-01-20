//! Boyer–Moore string search algorithm

/*

Good suffix rule:

- Case 1: Complete match of suffix

    s: ............b[ u ]............
    p:   ..[ u ]...a[ u ]
    p':           ..[ u ]...a[ u ]

- Case 2: Partial match of suffix

    s: .............b[ u1 ][ u2 ]....................
    p:     [ u2 ]...a[ u1 ][ u2 ]
    p':                    [ u2 ]...a[ u1 ][ u2 ]

- Case 3: No match

    s: ........b[ u ]............
    p:   ......a[ u ]
    p':              ......a[ u ]
*/

// NOTE: Here I use slightly different notations from the Wikipedia article, i.e., the index range
// of `s[a..b]` is $[a, b)$, where $a \in [0, n)$.

use std::cmp;

#[derive(Debug, Clone)]
enum GoodSuffix {
    /// Case 1 (highest priority)
    ///
    /// The 'L' table of **positions** in Wikipedia article (0-based here).
    /// L[i] := max(j) s.t. p[i..] == p[j - (n - i) .. j]
    Complete(usize),

    /// Case 2
    ///
    /// The 'H' table of **lengths** in Wikipedia article.
    /// H[i] := max(l) s.t. p[n - l ..] == p[..l]
    Partial(usize),

    /// Case 3
    NoMatch,
}


// #[derive(Debug)]
pub struct BoyerMoore<'a> {
    pub pattern: &'a [u8],
    bad_char: Vec<Vec<usize>>,
    good_suffix: Vec<GoodSuffix>,
}

impl<'a> BoyerMoore<'a> {
    pub fn from_pattern(p: &'a [u8]) -> BoyerMoore<'a> {
        assert!(!p.is_empty());
        // Builds map for bad-character shift
        //
        // Another (better?) approach is to use a 2D table (as described in
        // <https://en.wikipedia.org/wiki/Boyer–Moore_string_search_algorithm#Preprocessing>).
        let mut bad_char = std::iter::repeat(vec![]).take(256).collect::<Vec<_>>();
        for (i, &ch) in p.iter().enumerate().rev() {
            bad_char[ch as usize].push(i);
        }

        // Builds map for good-suffix shift
        let mut good_suffix = vec![GoodSuffix::NoMatch; p.len()];
        let i = p.len() - 1;
        'outer: for j_end in (1 .. p.len()).rev() { // open
            let mut jj = j_end - 1;
            let mut ii = i;
            loop {
                if p[jj] == p[ii] {
                    // It's a prefix
                    if jj == 0 {
                        loop {
                            if let GoodSuffix::NoMatch = good_suffix[ii] {
                                good_suffix[ii] = GoodSuffix::Partial(j_end);
                            }
                            // If it contains `GoodSuffix::Partial(len_old)`, then `len_old`
                            // must be larger than `j_end` so there is no need to update.

                            if ii == 0 {
                                break;
                            } else {
                                ii -= 1;
                            }
                        }
                        continue 'outer;
                    } else {
                        jj -= 1;
                        ii -= 1;
                    }
                } else { // not equal
                    for ii in (ii + 1) .. p.len() { // from the last one to the end
                        match good_suffix[ii] {
                            GoodSuffix::NoMatch |
                            GoodSuffix::Partial(_) => {
                                good_suffix[ii] = GoodSuffix::Complete(j_end);
                            }

                            // If it contains `GoodSuffix::Complete(j_end_old)`, then `j_end_old`
                            // must be larger than `j_end` so there is no need to update.
                            _ => (),
                        }
                    }
                    continue 'outer;
                }
            }
        }

        BoyerMoore {
            pattern: p,
            bad_char,
            good_suffix,
        }
    }

    // TODO: Optimization
    #[deprecated]
    fn compute_suffix(p: &[u8]) -> Vec<usize> {
        assert!(!p.is_empty());

        let mut suffix = vec![0; p.len() - 1];
        let i_end = p.len() - 1;
        'outer: for j in (0..i_end).rev() {
            let mut jj = j;
            let mut ii = i_end;
            loop {
                if p[jj] == p[ii] {
                    if jj == 0 {
                        suffix[j] = j + 1;
                        continue 'outer;
                    } else {
                        jj -= 1;
                        ii -= 1;
                    }
                } else {
                    suffix[j] = j - jj;
                    continue 'outer;
                }
            }
        }

        suffix
    }

    pub fn match_str(&self, s: &[u8]) -> Option<usize> {
        let p = self.pattern;
        if s.len() < p.len() {
            return None;
        }

        let mut i = 0;
        'outer: while i <= (s.len() - p.len()) {
            let mut j = p.len() - 1;
            loop {
                if s[i + j] != p[j] {
                    /* Bad character rule */
                    let mut i_delta_bc = 0;
                    // If it does not contain the bad character, skips as long as the pattern.
                    if self.bad_char[s[i + j] as usize].is_empty() {
                        i_delta_bc = p.len();
                    } else {
                        for &bc in self.bad_char[s[i + j] as usize].iter() {
                            if bc < j {
                                i_delta_bc = j - bc;
                                break;
                            }
                        }
                    }

                    /* Good suffix rule */
                    let j_last = j + 1;
                    let mut i_delta_gs = 0;
                    if j_last == p.len() {
                        // This means the first comparison does not match
                    } else {
                        i_delta_gs = match self.good_suffix[j] {
                            GoodSuffix::Complete(j_next) => p.len() - j_next,
                            GoodSuffix::Partial(l) => p.len() - l,
                            GoodSuffix::NoMatch => p.len(),
                        };
                    }

                    let i_delta = cmp::max(1,
                        cmp::max(i_delta_bc, i_delta_gs));
                    i += i_delta;
                    continue 'outer;
                }

                if j == 0 {
                    return Some(i);
                } else {
                    j -= 1;
                }
            }
        }

        None
    }
}


fn main() {
    let s = b"MANPANAMANAP";
    let p = b"ANAMPNAM";
    let boyer_moore = BoyerMoore::from_pattern(p);
    println!("{:?}", boyer_moore.bad_char[p[0] as usize]);
    println!("{:?}", boyer_moore.good_suffix);
    println!("{:?}", boyer_moore.match_str(s));
}
