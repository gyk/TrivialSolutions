use std::cmp::Ordering;

// Serial Number is introduced here as an extension method rather than a newtype (e.g. as in the
// [sna][sna] crate).
//
// [sna]: https://github.com/lgrahl/sna

/// RFC 1982 Serial Number Arithmetic
pub trait SerialNumber: Sized {
    fn sn_add(self, n: Self) -> Option<Self>;
    fn sn_sub(self, n: Self) -> Option<Self>;
    fn sn_cmp(&self, rhs: &Self) -> Option<Ordering>;
}

const MID: u32 = 1 << 31;

impl SerialNumber for u32 {

    // Serial numbers may be incremented by the addition of a positive integer n, where n is taken
    // from the range of integers [0 .. (2^(SERIAL_BITS - 1) - 1)]. For a sequence number s, the
    // result of such an addition, s', is defined as:
    //
    //     s' = (s + n) modulo (2 ^ SERIAL_BITS)
    fn sn_add(self, rhs: u32) -> Option<u32> {
        if rhs >= MID {
            // addend value out of range, undefined
            None
        } else {
            Some(self.wrapping_add(rhs))
        }
    }

    // s1 is said to be equal to s2 if and only if i1 is equal to i2, in all other cases, s1 is not
    // equal to s2.
    //
    // s1 is said to be less than s2 if, and only if, s1 is not equal to s2, and
    //
    //     (i1 < i2 and i2 - i1 < 2^(SERIAL_BITS - 1)) or
    //     (i1 > i2 and i1 - i2 > 2^(SERIAL_BITS - 1))
    //
    // s1 is said to be greater than s2 if and only if s2 is less than s1. Note that there are some
    // pairs of values s1 and s2 for which s1 is not equal to s2, but for which s1 is neither
    // greater than, nor less than, s2.
    fn sn_cmp(&self, rhs: &u32) -> Option<Ordering> {
        if self == rhs {
            Some(Ordering::Equal)
        } else if self < rhs {
            if *rhs - self < MID {
                Some(Ordering::Less)
            } else if *rhs - self > MID {
                Some(Ordering::Greater)
            } else {
                None
            }
        } else { // self > rhs
            if *self - rhs > MID {
                Some(Ordering::Less)
            } else if *self - rhs < MID {
                Some(Ordering::Greater)
            } else {
                None
            }
        }
    }

    // Not part of RFC 1982, added for convenience.
    fn sn_sub(self, rhs: u32) -> Option<u32> {
        match self.sn_cmp(&rhs) {
            None => None,
            Some(Ordering::Equal) => Some(0),
            Some(Ordering::Less) => None,
            Some(Ordering::Greater) => Some(self.wrapping_sub(rhs)),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_serial_number() {
        // sn_add
        assert_eq!(36.sn_add(64), Some(100));
        assert_eq!(0.sn_add(0x8000_0000), None);

        // sn_cmp
        assert_eq!(2.sn_cmp(&0xFFFF_FFFF), Some(Ordering::Greater));
        assert_eq!(1.sn_cmp(&0x8000_0000), Some(Ordering::Less));
        assert_eq!(0x0000_8000.sn_cmp(&0x0000_8000), Some(Ordering::Equal));
        assert_eq!(0xFFFF_FFF0.sn_cmp(&0xFFFF_FFFF), Some(Ordering::Less));
        assert_eq!(0xFFFF_FFFF.sn_cmp(&0xFFFF_FFFE), Some(Ordering::Greater));
        assert_eq!(0x0000_8000.sn_cmp(&0x8000_8000), None);
        assert_eq!(0xFFFF_FFFF.sn_cmp(&0x7FFF_FFFF), None);

        // sn_sub
        assert_eq!(10.sn_sub(0xFFFF_FFE0), Some(42));
        assert_eq!(0x8000_0001.sn_sub(1), None);
        assert_eq!(0x8000_0001.sn_sub(2), Some(0x7FFF_FFFF));
    }
}
