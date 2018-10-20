//! Bit Writer
use std::io::{Result, Write};

#[derive(Debug)]
pub struct BitWriter<W> {
    wr: W,
    byte: u8, // [ (8 - offset) bits of 0 | offset bits of written content ]
    offset: usize,
}

impl<W: Write> BitWriter<W> {
    pub fn new(wr: W) -> BitWriter<W> {
        BitWriter {
            wr,
            byte: 0,
            offset: 0,
        }
    }

    pub fn write(&mut self, is_one: bool) -> Result<()> {
        self.byte <<= 1;
        if is_one {
            self.byte |= 1;
        }
        self.offset += 1;
        if self.offset == 8 {
            self.wr.write_all(&[self.byte])?;
            self.byte = 0;
            self.offset = 0;
        }
        Ok(())
    }

    pub fn flush_leftover(&mut self) -> Result<()> {
        if self.offset == 0 {
            return Ok(());
        }

        let n_remaining = 8 - self.offset;
        self.write_n(false, n_remaining)
    }

    pub fn take_leftover(&mut self) -> (u8, usize) {
        let byte_offset = if self.offset == 0 {
            (0, 0)
        } else {
            (self.byte << (8 - self.offset), self.offset)
        };

        self.byte = 0;
        self.offset = 0;
        byte_offset
    }

    pub fn write_n(&mut self, is_one: bool, mut n: usize) -> Result<()> {
        let byte_template: u8 = if is_one {
            0xFF
        } else {
            0x00
        };

        if self.offset != 0 {
            let n_remaining = 8 - self.offset;
            let write_len = ::std::cmp::min(n_remaining, n);
            self.byte <<= write_len;
            let content: u8 = byte_template & ((1 << write_len) - 1);
            self.byte |= content;
            self.offset += write_len;
            n -= write_len;

            if self.offset == 8 {
                self.wr.write_all(&[self.byte])?;
                self.byte = 0;
                self.offset = 0;
            } else {
                return Ok(());
            }
        }

        while n >= 8 {
            self.wr.write_all(&[byte_template])?;
            n -= 8;
        }

        if n > 0 {
            self.byte = byte_template & ((1 << n) - 1);
            self.offset = n;
        }
        Ok(())
    }

    pub fn writer(self) -> W {
        debug_assert_eq!(self.offset, 0, "There is leftover in the BitWriter.");
        self.wr
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[cfg(test)]
    quickcheck! {
        fn prop_n_writes_write_n(b0: bool, n0: u8, b1: bool, n1: u8) -> bool {
            let result_n_writes = {
                let mut buffer = Vec::new();
                let leftover = {
                    let mut bwr = BitWriter::new(&mut buffer);
                    for _ in 0..n0 {
                        bwr.write(b0).unwrap();
                    }
                    for _ in 0..n1 {
                        bwr.write(b1).unwrap();
                    }
                    bwr.take_leftover()
                };
                (buffer, leftover)
            };

            let result_write_n = {
                let buffer = Vec::new();
                let mut bwr = BitWriter::new(buffer);
                bwr.write_n(b0, n0 as usize).unwrap();
                bwr.write_n(b1, n1 as usize).unwrap();

                let leftover = bwr.take_leftover();
                let buffer = bwr.writer();
                (buffer, leftover)
            };

            &result_n_writes.0[..] == &result_write_n.0[..] &&
            result_n_writes.1 == result_write_n.1
        }
    }
}
