use std::iter;
use std::mem;

#[inline]
unsafe fn take_at<T>(a: &mut [T], i: usize) -> T {
    mem::replace(&mut a[i], mem::uninitialized())
}

pub fn shell_sort<T: Ord>(a: &mut [T]) {
    let len = a.len();

    // Knuth's sequence
    let hs = iter::repeat(())
        .scan(0, |st, _| {
            if *st * 9 >= len {
                None
            } else {
                *st = *st * 3 + 1;
                Some(*st)
            }
        })
        .collect::<Vec<_>>();

    for h in hs.into_iter().rev() {
        // This loop is equivalent to iterating through every `h` element along with a nested loop
        // of `[0..h]`.
        for i in h .. len {
            let mut j = i;
            let mut temp = unsafe { take_at(a, j) };

            while j >= h && temp < a[j - h] {
                a[j] = unsafe { take_at(a, j - h) };
                j -= h;
            }

            a[j] = temp;
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn smoke() {
        let mut xs = vec![3, 4, 2, 7, 5, 8, 1, 6];
        shell_sort(&mut xs);
        assert_eq!(xs, (1..9).collect::<Vec<_>>());
    }

    quickcheck! {
        fn prop(xs: Vec<u32>) -> bool {
            let mut ys = xs.clone();
            shell_sort(&mut ys);
            let mut xs = xs;
            xs.sort();
            xs == ys
        }
    }
}
