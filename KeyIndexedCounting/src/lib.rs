//! # Key-indexed counting
//!
//! For details, refer to _Algorithms in C_ 6.10, by Robert Sedgewick.
//! Also note that `Quantizable` is not constrained to be `Copy`.

#[cfg(test)]
#[macro_use]
extern crate quickcheck;

use std::mem;

pub trait Quantizable {
    fn max_quantized_value() -> usize;
    fn quantize(&self) -> usize;
}

pub fn counting_sort<T: Quantizable>(xs: &mut Vec<T>) {
    let n = T::max_quantized_value() + 1;
    let mut cnt = vec![0; n];

    for x in xs.iter() {
        let q = x.quantize();
        cnt[q] += 1;
    }

    for i in 1 .. n {
        cnt[i] += cnt[i - 1];
    }

    let mut aux = Vec::with_capacity(xs.len());
    unsafe { aux.set_len(xs.len()); }

    let xs_taken = mem::replace(xs, Vec::new());
    // Reverses the iterator for stable sort
    for x in xs_taken.into_iter().rev() {
        let idx = x.quantize();
        aux[cnt[idx] - 1] = x;
        cnt[idx] -= 1;
    }

    mem::swap(xs, &mut aux);
}

impl Quantizable for u8 {
    fn max_quantized_value() -> usize {
        ::std::u8::MAX as usize
    }

    #[inline]
    fn quantize(&self) -> usize {
        *self as usize
    }
}

impl Quantizable for f32 {
    fn max_quantized_value() -> usize {
        ::std::f32::MAX.quantize()
    }

    fn quantize(&self) -> usize {
        if self.is_nan() {
            panic!("NaN is not supported");
        }

        let clamped = self.max(-1_f32).min(1_f32);
        ((clamped - (-1_f32)) / 0.1_f32).floor() as usize
    }
}


#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_f32() {
        let mut xs = vec![0.0, -0.03, -0.02, -0.01, -0.5, -1.0, -3.0, -2.0,
            1.01, 1.0, 0.99, 0.5, 0.111, 0.11, 0.1];
        let expected = vec![-1.0, -3.0, -2.0, -0.5, -0.03, -0.02, -0.01, 0.0,
            0.111, 0.11, 0.1, 0.5, 0.99, 1.01, 1.0];
        counting_sort(&mut xs);
        assert_eq!(xs, expected);
    }

    #[test]
    quickcheck! {
        fn prop_u8(xs: Vec<u8>) -> bool {
            let mut xs = xs;
            let mut xs_clone = xs.clone();
            counting_sort(&mut xs);
            xs_clone.sort();
            xs == xs_clone
        }
    }
}
