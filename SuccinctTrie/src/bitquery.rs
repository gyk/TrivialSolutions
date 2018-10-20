//! Implements `rank` and `select`.

// FIXME: `rank` and `select` can be greatly optimized using auxiliary arrays. This is important
// because by definition of succinct data strucuture, it "uses an amount of space that is 'close' to
// the information-theoretic lower bound, but (unlike other compressed representations) still allows
// for efficient query operations." However due to the upper bound of my free time, (unlike other
// programmers) I will not implement it efficient.

lazy_static! {
    static ref N_BITS_IN_BYTE: [u8; 256] = make_n_bits_in_byte();
    static ref MASK_TOP_0: [u8; 9] = make_mask_top(false);
    static ref MASK_TOP_1: [u8; 9] = make_mask_top(true);
}

fn make_n_bits_in_byte() -> [u8; 256] {
    let mut table = [0u8; 256];
    for i in 0..256 {
        table[i] = i.count_ones() as u8; // `popcnt`
    }
    table
}

fn make_mask_top(is_one: bool) -> [u8; 9] {
    let mut table = [0; 9];
    let mut mask = !0_u8;
    let mut i = 8;
    while mask != 0 {
        table[i] = if is_one {
            mask
        } else {
            !mask
        };
        mask <<= 1;
        i -= 1;
    }
    table
}

pub(crate) enum Select {
    Underflow,
    Position(usize),
    Overflow,
}

/// Returns the number of 0/1s up to position `x`.
///
/// - `x`: 0-based
/// - Return value: 1-based
pub(crate) fn rank(bit_vec: &[u8], is_one: bool, x: usize) -> usize {
    let n = x / 8;
    let r = x % 8;
    let but_last_cnt: u32;
    let last_cnt;
    if is_one {
        but_last_cnt = (0..n).map(|i| bit_vec[i].count_ones()).sum();
        last_cnt = if r == 0 {
            0
        } else {
            (bit_vec[n] & MASK_TOP_1[r]).count_ones()
        };
    } else {
        but_last_cnt = (0..n).map(|i| bit_vec[i].count_zeros()).sum();
        last_cnt = if r == 0 {
            0
        } else {
            (bit_vec[n] | MASK_TOP_0[r]).count_zeros()
        };
    }
    (but_last_cnt + last_cnt) as usize
}

// Oops, a very slow `select`.

/// Returns the position of the `x`-th occurrence of 0/1.
///
/// - `x`: 1-based
/// - Return value: 0-based
pub(crate)fn select(bit_vec: &[u8], is_one: bool, x: usize) -> Select {
    if x == 0 {
        return Select::Underflow;
    }

    let mut cnt = 0;
    let mut i = 0;
    while i < bit_vec.len() {
        let byte_cnt = if is_one {
            bit_vec[i].count_ones()
        } else {
            bit_vec[i].count_zeros()
        } as usize;
        if cnt + byte_cnt < x {
            cnt += byte_cnt;
            i += 1;
        } else {
            break;
        }
    }
    // Now `cnt` contains bit count before (i.e., exclusively) index `i`.
    if i == bit_vec.len() {
        if cnt < x {
            return Select::Overflow;
        } else {
            unreachable!();
        }
    }

    let n_remaining = x - cnt;
    let i_remaining = if n_remaining == 0 {
        0
    } else {
        let last_byte = bit_vec[i];
        (1 ..= 8).find(|&i| {
            let last_cnt = if is_one {
                (last_byte & MASK_TOP_1[i]).count_ones()
            } else {
                (last_byte | MASK_TOP_0[i]).count_zeros()
            } as usize;

            last_cnt == n_remaining
        }).expect("Cannot find position in the last byte.")
        - 1  // cardinal to 0-based ordinal
    };

    Select::Position(i * 8 + i_remaining)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[cfg(test)]
    quickcheck! {
        fn prop_select_rank(bit_vec: Vec<u8>, is_one: bool, x: usize) -> bool {
            let x = x % (bit_vec.len() * 8 + 1); // deliberately +1

            let p = rank(&bit_vec, is_one, x);
            match select(&bit_vec, is_one, p) {
                Select::Underflow => p == 0,
                Select::Position(y) => x >= y,
                Select::Overflow => false,
            }
        }
    }
}
