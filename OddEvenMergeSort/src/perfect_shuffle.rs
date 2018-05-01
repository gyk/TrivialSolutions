//! Perfect shuffle/unshuffle

// ===== Perfect shuffle/unshuffle, using auxiliary array =====

/// Perfect shuffle, using auxiliary array
pub(crate) fn shuffle<T: Copy>(a: &mut [T]) {
    let n = a.len();
    assert_eq!(n % 2, 0, "The length should be even");
    let m = n / 2;
    let mut aux = Vec::with_capacity(n);
    unsafe { aux.set_len(n); }
    for i in 0..m {
        aux[i * 2] = a[i];
    }
    for i in m..n {
        // i' = (n - 1) - (n - 1 - i) * 2 => i' = i * 2 - (n - 1)
        aux[i * 2 - n + 1] = a[i];
    }
    a.clone_from_slice(&aux);
}

/// Perfect unshuffle, using auxiliary array
pub(crate) fn unshuffle<T: Copy>(a: &mut [T]) {
    let n = a.len();
    assert_eq!(n % 2, 0, "The length should be even");
    let mut aux = Vec::with_capacity(n);
    unsafe { aux.set_len(n); }
    let mut i = 0;
    while i < n {
        aux[i / 2] = a[i];
        i += 1;
        aux[(i + n - 1) / 2] = a[i];
        i += 1;
    }
    a.clone_from_slice(&aux);
}

// ===== In-place perfect shuffle/unshuffle, using recursion =====
//
// How it works:
//
// Due to the symmetry nature of perfect shuffle, i.e., an even (0-based) indexed element at 'i' is
// transformed to `i * 2`, while an odd one is transformed to `i' * 2`, where `i' = n - 1 - i` is
// the index backwards. Therefore to shuffle array `a`, we consider its 4 subarrays of the same
// length: `a = [a0 a1 a2 a3]`. After calling `shuffle([a0 a1])` and `shuffle([a2 a3])`, the
// transformations from `a0` and `a3` are at the final positions, but those from `a1` should be
// further swapped with those from `a2`.

/// In-place perfect shuffle, using recursion.
pub(crate) fn shuffle_in_place<T: Copy>(a: &mut [T]) {
    let n = a.len();
    assert_eq!(n.next_power_of_two(), n, "The length should be a power of 2");
    shuffle_in_place_r(a);
}

fn shuffle_in_place_r<T: Copy>(a: &mut [T]) {
    let n = a.len();
    let m = n / 2;
    if m >= 4 {
        shuffle_in_place_r(&mut a[..m]);
        shuffle_in_place_r(&mut a[m..]);
    }
    for i in (0..m).step_by(2) {
        a.swap(i + 1, i + m);
    }
}

/// In-place perfect unshuffle, using recursion.
pub(crate) fn unshuffle_in_place<T: Copy>(a: &mut [T]) {
    let n = a.len();
    assert_eq!(n.next_power_of_two(), n, "The length should be a power of 2");
    unshuffle_in_place_r(a);
}

fn unshuffle_in_place_r<T: Copy>(a: &mut [T]) {
    let n = a.len();
    let m = n / 2;

    for i in (0..m).step_by(2) {
        a.swap(i + 1, i + m);
    }
    if m >= 4 {
        unshuffle_in_place_r(&mut a[..m]);
        unshuffle_in_place_r(&mut a[m..]);
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
    fn shuffle_smoke() {
        let a = (0..8).collect::<Vec<_>>();
        let expected = &[0, 4, 1, 5, 2, 6, 3, 7];
        let mut a_cloned = a.clone();
        let xs = &mut a_cloned[..];

        shuffle(xs);
        assert_eq!(xs, expected);
        unshuffle(xs);
        assert_eq!(xs, &a[..]);

        shuffle_in_place(xs);
        assert_eq!(xs, expected);
        unshuffle_in_place(xs);
        assert_eq!(xs, &a[..]);
    }

    // unshuffle . shuffle == identity
    // shuffle . unshuffle == identity
    #[test]
    quickcheck! {
        fn prop_shuffle_unshuffle(xs: Vec<u8>) -> bool {
            if xs.len() < 2 {
                return true;
            }

            let mut xs = xs;
            truncate_to_last_power_of_two(&mut xs);
            let old_xs = xs.clone();
            shuffle(&mut xs);
            unshuffle(&mut xs);
            &xs[..] == &old_xs[..]
        }

        fn prop_shuffle_unshuffle_in_place(xs: Vec<u8>) -> bool {
            if xs.len() < 2 {
                return true;
            }

            let mut xs = xs;
            truncate_to_last_power_of_two(&mut xs);
            let old_xs = xs.clone();
            shuffle_in_place(&mut xs);
            unshuffle_in_place(&mut xs);
            &xs[..] == &old_xs[..]
        }
    }
}
