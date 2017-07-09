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

// Optimization using lookup table

const CRC_ISO_13818_1: u32 = 0x04C11DB7; // MSBit-first
const CRC_IEEE: u32 = 0xEDB88320; // MSBit-first
lazy_static! {
    static ref CRC32_TABLE_MSB: [u32; 256] = make_table_msb(CRC_ISO_13818_1);
    static ref CRC32_TABLE_LSB: [u32; 256] = make_table_lsb(CRC_IEEE);
}

/*

Derivation of the table, taking MSBit-first as an example:

    tbl[v] := v * 2^32 % poly
    
      (v * 2^8 * 2^32 + u * 2^32) % poly
    = (tbl[v] * 2^8 + u * 2^32) % poly
    = ((tbl[v] >> 24 + u) * 2^32) % poly + (tbl[v] & 0xFF_FFFF) * 2^8 % poly
    = tbl[tbl[v] >> 24 ^ u] + (tbl[v] & 0xFF) << 8

*/

// MSBit-first
fn make_table_msb(poly: u32) -> [u32; 256] {
    let mut table = [0u32; 256];
    for i in 0..256 {
        let mut value = (i as u32) << 24;
        for _ in 0..8 {
            value = {
                if (value & 0x8000_0000) != 0 {
                    (value << 1) ^ poly
                } else {
                    value << 1
                }
            };
        }
        table[i] = value;
    }
    table
}

pub fn crc32_msb(data: &[u8]) -> u32 {
    let mut res: u32 = 0xFFFF_FFFF;
    for &i in data.iter() {
        res = (res << 8) ^ CRC32_TABLE_MSB[(i ^ (res >> 24) as u8) as usize];
    }
    res
}

// LSBit-first
pub fn make_table_lsb(poly: u32) -> [u32; 256] {
    let mut table = [0u32; 256];
    for i in 0..256 {
        let mut value = i as u32;
        for _ in 0..8 {
            value = {
                if (value & 1) == 1 {
                    (value >> 1) ^ poly
                } else {
                    value >> 1
                }
            }
        }
        table[i] = value;
    }
    table
}

pub fn crc32_lsb(data: &[u8]) -> u32 {
    let mut res: u32 = 0xFFFF_FFFF;
    for &i in data.iter() {
        res = CRC32_TABLE_LSB[((res as u8) ^ i) as usize] ^ (res >> 8)
    }
    !res
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

    #[test]
    fn test_crc32_table() {
        let data = [
            0x00, 0xB0, 0x0D, 0x00, 0x01, 0xC1, 0x00, 0x00,
            0x00, 0x01, 0xF0, 0x01,
        ];

        assert_eq!(crc32_msb(&data), 0x2E701905);
        assert_eq!(crc32_lsb(b"123456789"), 0xcbf43926);
    }
}
