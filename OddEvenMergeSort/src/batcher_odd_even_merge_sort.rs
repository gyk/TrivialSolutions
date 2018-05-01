//! # Batcher's Odd-even merge sort
//!
//! A nonadaptive sorting algorithm that can easily run in parallel.

use perfect_shuffle::{shuffle, unshuffle};

// The correctness of Batcher's odd-even merge can be proved by 0-1 principle. Here is another
// explanation which is easier to understand:
//
// To sort `a` (ascendingly, without loss of generality), we
//
// 1. Sort its two halves `[a0 a1]`
// 2. Sort its even-indexed (0-based indexing is used throughout the whole documentation) and
//    odd-indexed subarrays respectively
// 3. Finally, compare-and-swap element pairs `(1, 2), (3, 4), ..., (n-3, n-2)`
//
// Now `a` should have been sorted. To see this, we consider how the `k`-th smallest element is put
// at its expected position. There are 4 cases in total:
//
// 1. k: even, l: even, r: even
// 2. k: even, l: odd, r: odd
// 3. k: odd, l: even, r: odd; k in the left half
//     - The same as: k: odd, l: odd, r: even; k-th element in the right half
// 4. k: odd, l: even, r: odd; k in the right half
//     - The same as: k: odd, l: odd, r: even; k-th element in the left half
//
// Case 1 is trivial. For Case 2, since `l` and `r` are both odd, after Step 2 we have two more
// even-indexed elements than odd-indexed ones. And the `k`-th element is placed at odd index, so
// after Step 2, it is just before `(k-1)`-th smallest element. Therefore Step 3 makes the whole
// array completely sorted.
//
// An example (here `0`s represent even-indexed elements while `1`s represent odd-indexed ones. `*`
// is the 8th smallest element):
//
// - Input:
//     - Left half: `0 1 0 * ...`
//     - Right half: `0 1 0 1 0 ...`
//     - It is Case 2: k = 8 (even), l = 3 (odd), r = 5 (odd)
// - After Step 2: `0 1 0 1 0 1 0 * 0 ...`
// - But we need `0 1 0 1 0 1 0 0 * ...`. Now Step 3 comes to the rescue: each `1`-marked element is
//   compare-and-swapped with the `0`-marked one following it.
//
// Case 3 and 4 can be proved with the similar technique.

/* ===== Implementation based on Robert Sedgewick's Algorithms in C, 11.1 ===== */
// Note that the code in the book is wrong (forgetting to call `merge` before `unshuffle`).

#[inline]
fn compare_and_swap<T: Ord>(a: &mut [T], i: usize, j: usize) {
    if a[i] > a[j] {
        a.swap(i, j);
    }
}

/// Odd-even merge sort by shuffling.
pub fn odd_even_merge_top_down<T: Ord + Copy>(a: &mut [T]) {
    let n = a.len();
    assert_eq!(n.next_power_of_two(), n, "The length should be a power of 2");
    odd_even_merge_r(a);
}

fn odd_even_merge_r<T: Ord + Copy>(a: &mut [T]) {
    let n = a.len();
    if n == 2 {
        compare_and_swap(a, 0, 1);
        return;
    }
    let m = n / 2;

    odd_even_merge_r(&mut a[..m]);
    odd_even_merge_r(&mut a[m..]);
    unshuffle(a);
    odd_even_merge_r(&mut a[..m]);
    odd_even_merge_r(&mut a[m..]);
    shuffle(a);

    for i in (1 .. n - 1).step_by(2) {
        compare_and_swap(a, i, i + 1);
    }
}

// ----------------8<----------------

/* ===== Implementation from Wikipedia ===== */
//
// ```python
// >>> list(oddeven_merge(0, 7, 1))
// [(0, 4), (2, 6), (2, 4), (1, 5), (3, 7), (3, 5), (1, 2), (3, 4), (5, 6)]
// ```

/// Odd-even merge sort without shuffling.
pub fn odd_even_merge2<T: Ord + Copy>(a: &mut [T]) {
    let n = a.len();
    assert_eq!(n.next_power_of_two(), n, "The length should be a power of 2");

    let mut network = Vec::new();
    odd_even_merge_sorting_network(0, n - 1, &mut network);
    for &(u, v) in network.iter() {
        compare_and_swap(a, u, v);
    }
}

fn odd_even_merge_sorting_network(start: usize, end: usize,
    network: &mut Vec<(usize, usize)>)
{
    if start == end {
        return;
    }
    let mid = start + (end - start + 1) / 2;

    odd_even_merge_sorting_network(start, mid - 1, network);
    odd_even_merge_sorting_network(mid, end, network);
    // Now the first half and the second half are both sorted.
    odd_even_merge_sorting_network_r(start, end, 1, network);
}

// Explicitly generates the sorting network and then does all the "compare-and-swap" operations.
fn odd_even_merge_sorting_network_r(start: usize, end: usize, offset: usize,
    network: &mut Vec<(usize, usize)>)
{
    let step = offset * 2;
    if step < end - start {
        odd_even_merge_sorting_network_r(start, end - offset, step, network);
        odd_even_merge_sorting_network_r(start + offset, end, step, network);
        for i in ((start + offset)..(end - offset)).step_by(step) {
            network.push((i, i + offset));
        }
    } else {
        network.push((start, start + offset));
    }
}


#[cfg(test)]
mod tests {
    use super::*;

    fn truncate_to_last_power_of_two<T>(a: &mut Vec<T>) {
        let mut new_len = a.len().next_power_of_two();
        if new_len > a.len() {
            new_len /= 2;
        }
        a.truncate(new_len);
    }

    #[test]
    quickcheck! {
        fn prop_odd_even_merge_sort(xs: Vec<u32>) -> bool {
            if xs.len() < 2 {
                return true;
            }

            let mut xs = xs;
            truncate_to_last_power_of_two(&mut xs);

            let mut xs_copy1 = xs.clone();
            odd_even_merge2(&mut xs_copy1);

            let mut xs_copy2 = xs.clone();
            odd_even_merge2(&mut xs_copy2);

            let mut expected = xs;
            expected.sort();

            &xs_copy1[..] == &expected[..] &&
            &xs_copy2[..] == &expected[..]
        }
    }
}
