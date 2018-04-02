//! Computes running medians of a sequence.
//!
//! It is worth noting that running median is different from "moving median" or "rolling median"
//! (medians within a sliding window).
//!

#![feature(conservative_impl_trait)]

#[cfg(test)]
#[macro_use]
extern crate quickcheck;

mod rev_ord;

use std::collections::BinaryHeap;

use rev_ord::RevOrd;

pub fn running_median_insertion<T, I>(xs: I) -> impl Iterator<Item = T>
    where T: Ord + Clone, I: Iterator<Item = T>
{
    let mut v = match xs.size_hint() {
        (_, Some(ub)) => Vec::with_capacity(ub),
        _ => Vec::new(),
    };

    xs.map(move |x| {
        // Requires `upper_bound`. See RFCS 2184.
        match v.binary_search(&x) {
            Ok(i) => v.insert(i + 1, x),
            Err(i) => v.insert(i, x),
        }

        v[(v.len() - 1) / 2].clone()
    })
}

pub fn running_median_two_heaps<T, I>(xs: I) -> impl Iterator<Item = T>
    where T: Ord + Clone, I: Iterator<Item = T>
{
    let mut max_heap = match xs.size_hint() {
        (_, Some(ub)) => BinaryHeap::with_capacity(ub),
        _ => BinaryHeap::new(),
    };
    let mut min_heap: BinaryHeap<RevOrd<_>> = BinaryHeap::with_capacity(max_heap.capacity());

    xs.map(move |x| {
        if max_heap.is_empty() {
            max_heap.push(x);
        } else {
            if &x < max_heap.peek().unwrap() {
                max_heap.push(x);
            } else {
                min_heap.push(RevOrd(x));
            }

            if max_heap.len() > min_heap.len() + 1 {
                debug_assert_eq!(max_heap.len(), min_heap.len() + 2);
                let x = max_heap.pop().unwrap();
                min_heap.push(RevOrd(x));
            } else if max_heap.len() < min_heap.len() {
                debug_assert_eq!(max_heap.len() + 1, min_heap.len());
                let x = min_heap.pop().unwrap().0;
                max_heap.push(x);
            }
        }

        return max_heap.peek().unwrap().clone();
    })
}

// More efficient algorithm for "quantizable" input.
//
// Solution using segment tree has good time complexity and flexibility (can be generalized to other
// quantiles) but may not be terribly easy to implement. Here we use a modified version of counting
// sort as proposed in <https://stackoverflow.com/a/1625442/3107204>.
pub fn running_median_quantized<I>(xs: I, value_range: usize) -> impl Iterator<Item = usize>
    where I: Iterator<Item = usize>
{
    let mut count = 0;
    let mut buckets = vec![0; value_range];
    let mut m_i = 0;
    let mut sum_m = 0;
    xs.map(move |x| {
        count += 1;
        buckets[x] += 1;
        if x < m_i {
            sum_m += 1;
        }

        // Gets the median
        let half_i = (count - 1) / 2;
        loop {
            if half_i < sum_m {
                m_i -= 1;
                sum_m -= buckets[m_i];
            } else if sum_m + buckets[m_i] < half_i + 1 {
                sum_m += buckets[m_i];
                m_i += 1;
            } else {
                return m_i;
            }
        }
    })
}


#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    quickcheck! {
        fn prop_two_heaps(xs: Vec<u16>) -> bool {
            let res_insertion = running_median_insertion(xs.iter());
            let res_two_heaps = running_median_insertion(xs.iter());
            res_insertion.eq(res_two_heaps)
        }

        fn prop_quantized(xs: Vec<u8>) -> bool {
            let res_insertion = running_median_insertion(xs.iter().map(|&x| x as usize));
            let res_quantized = running_median_quantized(xs.iter().map(|&x| x as usize),
                std::u8::MAX as usize);
            res_insertion.eq(res_quantized)
        }
    }
}
