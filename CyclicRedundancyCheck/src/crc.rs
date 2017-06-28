//! Cyclic redundancy check
//!
//! Polynomial division over GF(2) == bitwise add/sub discarding the carry == XOR
//! See <https://en.wikipedia.org/wiki/Mathematics_of_cyclic_redundancy_checks>.

// TODO: this will be moved to `std::collections` in Rust 1.2, probably.
use bit_vec::BitVec;

pub fn crc32_bitvec(mut data: BitVec, polynomial: BitVec) -> BitVec {
    assert_eq!(polynomial[0], true);
    assert_eq!(polynomial[polynomial.len() - 1], true);

    let data_len = data.len();
    let order = polynomial.len() - 1;

    // (data ++ fill) `mod` poly == 0
    data.grow(order, false);

    for i in 0..data_len {
        if data[i] == true {
            for j in 0..(order + 1) {
                // When do we have non-lexical lifetime and IndexSet trait?
                let xor = data[i + j] ^ polynomial[j];
                data.set(i + j, xor);
            }
        }
    }

    let mut check = BitVec::from_elem(order, false);
    for i in 0..order {
        check.set(i, data[data_len + i]);
    }

    check
}

pub fn crc32_slice(data: &[u8], polynomial: &[u8]) -> Vec<u8> {
    crc32_bitvec(BitVec::from_bytes(data), BitVec::from_bytes(polynomial)).to_bytes()
}

mod test {
    use super::*;

    #[test]
    fn test_crc32_bitvec() {
        let mut data = BitVec::default();
        for b in &[1, 1, 0, 1, 0, 0, 1, 1, 1, 0, 1, 1, 0, 0] {
            data.push(*b == 1);
        }

        let mut poly = BitVec::default();
        for b in &[1, 0, 1, 1] {
            poly.push(*b == 1);
        }

        assert!(crc32_bitvec(data, poly).eq_vec(&[true, false, false]));
    }
}
