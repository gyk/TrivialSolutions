//! Burrows–Wheeler transform in Rust.
//!
//! The [Wikipedia article][wiki] has very clear explanation. For understanding the tricks of
//! optimization, this [SO answer][so] might be helpful, although there are several mistakes in it.
//!
//! [wiki]: https://en.wikipedia.org/wiki/Burrows–Wheeler_transform
//! [so]: https://stackoverflow.com/a/8055554/3107204


#[cfg(test)]
#[macro_use]
extern crate quickcheck;

mod wrap_str;
use wrap_str::WrapStr;

/// Returns the last column after BW transformation, and the index of the original text.
pub fn burrows_wheeler<T>(s: &[T]) -> (Vec<T>, usize)
    where T: Ord + Clone + 'static
{
    let len = s.len();
    debug_assert!(len > 0);

    let mut rotated = Vec::with_capacity(len);
    for i in 0..len {
        rotated.push(WrapStr::new(s, i));
    }

    // For simplicity, just uses the built-in `sort` function, which is stable.
    // It has terrible worst-case time complexity.
    rotated.sort();

    let mut result = Vec::with_capacity(len);
    let mut start_idx: Option<usize> = None;
    for i in 0..len {
        if rotated[i].start_index == 0 {
            start_idx = Some(i);
        }
        result.push(rotated[i][len - 1].clone());
    }

    (result, start_idx.unwrap())
}

pub fn inv_burrows_wheeler<T>(s: &[T], start_index: usize) -> Vec<T>
    where T: Ord + Clone + 'static
{
    let len = s.len();
    debug_assert!(len > start_index);

    let mut sorted = Vec::with_capacity(len);
    // What is the new position of the `s[i]` after sorting?
    let mut index_map = vec![0; len];

    let mut pair_vec = (0..len)
        .map(|i| (i, &s[i]))  // single character
        .collect::<Vec<_>>();
    pair_vec.sort_by_key(|x| x.1);
    pair_vec
        .into_iter()
        .enumerate()
        .for_each(|(i, (origin_i, ch))| {
            sorted.push(ch);
            index_map[origin_i] = i;
        });

    let mut recovered = Vec::with_capacity(len);
    unsafe { recovered.set_len(len); }

    let mut next_idx = start_index;
    for i in (0..len).rev() {
        recovered[i] = s[next_idx].clone();
        next_idx = index_map[next_idx];
    }

    recovered
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn bwt_smoke() {
        // The example from Wikipedia. Note that we explicitly store start index rather than
        // attaching an EOF.
        let text = b"^BANANA|";
        let (xformed, start_idx) = burrows_wheeler(&text[..]);
        println!("{:?}, {}", xformed, start_idx);

        let recovered = inv_burrows_wheeler(&xformed, start_idx);
        println!("{:?}", recovered);
        assert_eq!(&text[..], &recovered[..]);
    }

    #[test]
    quickcheck! {
        fn prop(xs: Vec<u8>) -> bool {
            if xs.is_empty() {
                return true;
            }

            let (xformed, start_idx) = burrows_wheeler(&xs);
            let recovered = inv_burrows_wheeler(&xformed, start_idx);
            xs == &recovered[..]
        }
    }
}
