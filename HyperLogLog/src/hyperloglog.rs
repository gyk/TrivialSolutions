//! HyperLogLog

// The usage of poissonization/depoissonization to derive harmonic mean in the HyperLogLog paper
// seems so brilliant but I don't really understand most of the details in the proof.

use std::cmp;
use std::hash::{BuildHasher, Hash, Hasher};
use std::marker::PhantomData;

pub struct HyperLogLog<V, BH> {
    m: u64,
    alpha: f64,
    registers: Vec<i32>,
    build_hasher: BH,
    _v: PhantomData<V>,
}

impl<V: Hash, BH: BuildHasher> HyperLogLog<V, BH> {
    pub fn new(b: u64, build_hasher: BH) -> HyperLogLog<V, BH> {
        if b > 32 {
            panic!("`b` is so large that I can't help panicking :O");
        }

        let m = 1 << b;
        HyperLogLog {
            m,
            alpha: Self::compute_alpha(m),
            registers: vec![0; m as usize],
            build_hasher,
            _v: PhantomData,
        }
    }

    // We need const-fn
    fn compute_alpha(m: u64) -> f64 {
        if m <= 31 {
            0.673
        } else if m <= 63 {
            0.697
        } else if m <= 127 {
            0.709
        } else {
            0.7213 / (1.0 + 1.079 / (m as f64))
        }
    }

    pub fn add(&mut self, value: &V) {
        let mut hasher = self.build_hasher.build_hasher();
        value.hash(&mut hasher);
        let x = hasher.finish();
        let mask = self.m - 1;

        // Splits `x` into `[w | j]`, rather than `[j | w]` as in the paper.
        let j = (x & mask) as usize;
        // Implicit `w` computation. Will generate "llvm.ctlz" instruction.
        let rho = (x | mask).leading_zeros() + 1;
        self.registers[j] = cmp::max(rho as i32, self.registers[j]);
    }

    // FIXME: totally untested function
    fn correct(&self, raw_estimate: f64) -> f64 {
        let m = self.m as f64;
        if raw_estimate <= (5.0 / 2.0) * m {
            let zero_reg_cnt = self.registers
                .iter()
                .filter(|&r| *r == 0)
                .count();
            if zero_reg_cnt != 0 {
                m * (m / (zero_reg_cnt as f64)).ln()
            } else {
                raw_estimate
            }
        } else if raw_estimate <= (1.0 / 30.0) * 2.0_f64.powi(32) {
            raw_estimate
        } else {
            -(2.0_f64.powi(32) * (1.0 - raw_estimate / 2.0_f64.powi(32)).ln())
        }
    }

    pub fn count(&self) -> usize {
        let z_inv: f64 = self.registers
            .iter()
            .map(|&r| 2.0_f64.powi(-r))
            .sum();

        let m = self.m as f64;
        let raw_estimate = self.alpha * m * m / z_inv;
        self.correct(raw_estimate) as usize
    }
}
