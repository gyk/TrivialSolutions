//! Arithmetic over GF(2^8)


// Notes on Finite Field:
//
// If a⋅b = 0 then a or b must be 0. Indeed, if a ≠ 0, then 0 = a^(–1)⋅0 = a^(–1)⋅(ab) = (a^(–1)a)b
// = b. For any composite number, Z/nZ is not a field: the product of two non-zero elements is zero
// since r⋅s = 0 in Z/nZ, which prevents Z/nZ from being a field.
//
// From <https://stackoverflow.com/a/1993697/>:
//
// First pick an irreducible polynomial of degree n over GF[p]. ... Then your elements in GF[p^n]
// are just n-degree polynomials over GF[p]. Just do normal polynomial arithmetic and make sure to
// compute the remainder modulo your irreducible polynomial.

// https://research.swtch.com/field
// https://math.stackexchange.com/questions/312186/
// https://math.stackexchange.com/questions/542044/

use std::ops::{Add, Div, Mul, Neg, Rem, Sub};

use lazy_static::lazy_static;
use num::{Zero, One};
use num::Bounded;
use num_traits::Inv;
use rand::prelude::*;
use rand::distributions::uniform::{SampleBorrow, SampleUniform, UniformSampler, UniformInt};

#[derive(Default, Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
pub struct Gf256Elm(u8);

// ===== Conversion =====

impl From<u8> for Gf256Elm {
    fn from(x: u8) -> Self {
        Gf256Elm(x)
    }
}

impl From<Gf256Elm> for u8 {
    fn from(x: Gf256Elm) -> Self {
        x.0
    }
}

// ===== `num` Traits =====

impl Zero for Gf256Elm {
    fn zero() -> Self {
        Gf256Elm(0)
    }

    fn is_zero(&self) -> bool {
        self.0 == 0
    }
}

impl One for Gf256Elm {
    fn one() -> Self {
        Gf256Elm(1)
    }
}

impl Bounded for Gf256Elm {
    fn min_value() -> Self {
        Gf256Elm(0)
    }
    fn max_value() -> Self {
        Gf256Elm(255)
    }
}

// ===== Arithmetic Operations =====

impl Add for Gf256Elm {
    type Output = Self;

    fn add(self, other: Gf256Elm) -> Self::Output {
        Gf256Elm(self.0 ^ other.0)
    }
}

impl Sub for Gf256Elm {
    type Output = Self;

    fn sub(self, other: Gf256Elm) -> Self::Output {
        Gf256Elm(self.0 ^ other.0)
    }
}

impl Mul for Gf256Elm {
    type Output = Self;

    fn mul(self, other: Gf256Elm) -> Self::Output {
        if self.is_zero() || other.is_zero() {
            return Gf256Elm::zero();
        }

        let index = LOG_TABLE[self.0 as usize] as usize + LOG_TABLE[other.0 as usize] as usize;
        Gf256Elm(EXP_TABLE[index])
    }
}

impl Neg for Gf256Elm {
    type Output = Gf256Elm;

    fn neg(self) -> Self::Output {
        Gf256Elm::zero() - self
    }
}

impl Inv for Gf256Elm {
    type Output = Gf256Elm;

    fn inv(self) -> Self::Output {
        Gf256Elm(EXP_TABLE[255 - LOG_TABLE[self.0 as usize] as usize])
    }
}

impl Div for Gf256Elm {
    type Output = Self;

    fn div(self, other: Gf256Elm) -> Self::Output {
        if other.is_zero() {
            panic!("Divide by zero: {:?}/{:?}", self, other)
        }

        if self.is_zero() {
            return Gf256Elm::zero();
        }

        let index = LOG_TABLE[self.0 as usize] as usize + 255 -
            LOG_TABLE[other.0 as usize] as usize;
        Gf256Elm(EXP_TABLE[index])
    }
}

// This is only for automatically implementing `NumOps`
impl Rem for Gf256Elm {
    type Output = Self;

    fn rem(self, _rhs: Gf256Elm) -> Self::Output {
        unimplemented!()
    }
}

// ===== Rijndael's Finite Field =====
// A field based on the irreducible polynomial $X^8 + X^4 + X^3 + X + 1$.

// 0b11 ^ 0 == 0b11 ^ 255 == 1  (GF(2^8))
const _RIJNDAEL_GENERATOR: u8 = 0b11;

// x * RIJNDAEL_GENERATOR = x ^ (x << 1)  (mod 0x11b), but `x << 1` may overflow, so if it does
// overflow just computes `x ^ (x << 1) ^ RIJNDAEL_REMAINDER`.
//
// This trick can be found in William Stallings's Cryptography and Network Security, but actually we
// don't need it as we have already used lookup tables.
const RIJNDAEL_REMAINDER: u8 = 0b1_1011;

fn make_exp_tables() -> [u8; 256 * 2] {
    let mut exp_table = [0; 256 * 2];

    let mut curr: u8 = 1;
    for i in 0..256 {
        exp_table[i] = curr;
        exp_table[i + 255] = curr;
        curr = curr ^ (curr << 1) ^ (if curr & (1 << 7) != 0 { RIJNDAEL_REMAINDER } else { 0 });
    }
    assert_eq!(exp_table[0], exp_table[255]);

    exp_table
}

// `log_table[0]` is actually N/A.
fn log_table_from_exp_table(exp_table: &[u8; 256 * 2]) -> [u8; 256 * 2] {
    let mut log_table = [0; 256 * 2];

    // `rev()` because I prefer `log_table[1]` being 0 rather than 255.
    for i in (0..256).rev() {
        let index = exp_table[i] as usize;
        log_table[index] = i as u8;
        log_table[index + 255] = i as u8;
    }

    log_table
}

// TODO: const_fn
lazy_static! {
    // Uses double sized tables to save a `% 255` operation.
    static ref EXP_TABLE: [u8; 256 * 2] = make_exp_tables();
    static ref LOG_TABLE: [u8; 256 * 2] = log_table_from_exp_table(&EXP_TABLE);
}

// ===== Random Sampling =====

#[derive(Clone, Copy, Debug)]
pub struct UniformGf256 {
    inner: UniformInt<u8>,
}

impl UniformSampler for UniformGf256 {
    type X = Gf256Elm;
    fn new<B1, B2>(low: B1, high: B2) -> Self
        where
            B1: SampleBorrow<Self::X> + Sized,
            B2: SampleBorrow<Self::X> + Sized,
    {
        UniformGf256 {
            inner: UniformInt::<u8>::new(low.borrow().0, high.borrow().0),
        }
    }
    fn new_inclusive<B1, B2>(low: B1, high: B2) -> Self
        where
            B1: SampleBorrow<Self::X> + Sized,
            B2: SampleBorrow<Self::X> + Sized,
    {
        UniformSampler::new(low, high)
    }
    fn sample<R: Rng + ?Sized>(&self, rng: &mut R) -> Self::X {
        Gf256Elm(self.inner.sample(rng))
    }
}

impl SampleUniform for Gf256Elm {
    type Sampler = UniformGf256;
}

#[cfg(test)]
mod tests {
    use super::*;

    use proptest::prelude::*;

    #[test]
    fn test_convert() {
        assert_eq!(Gf256Elm::from(42_u8), Gf256Elm(42));
        assert_eq!(u8::from(Gf256Elm(100)), 100_u8);
    }

    #[test]
    fn test_01() {
        assert_eq!(Gf256Elm(0), Gf256Elm::zero());
        assert_eq!(Gf256Elm(1), Gf256Elm::one());
    }

    // Plagiarize test cases from @codehale's implementation
    #[test]
    fn test_mul() {
        assert_eq!(Gf256Elm(90) * Gf256Elm(21), Gf256Elm(254));
        assert_eq!(Gf256Elm(133) * Gf256Elm(5), Gf256Elm(167));

        // One term is 0
        assert_eq!(Gf256Elm(21) * Gf256Elm(0), Gf256Elm(0));
        assert_eq!(Gf256Elm(0) * Gf256Elm(21), Gf256Elm(0));
    }

    #[test]
    fn test_div() {
        assert_eq!(Gf256Elm(90) / Gf256Elm(21), Gf256Elm(189));
        assert_eq!(Gf256Elm(6) / Gf256Elm(55), Gf256Elm(151));
        assert_eq!(Gf256Elm(22) / Gf256Elm(192), Gf256Elm(138));

        // The dividend is 0
        assert_eq!(Gf256Elm(0) / Gf256Elm(21), Gf256Elm(0));
    }

    #[test]
    fn test_random() {
        use rand::Rng;
        use rand::distributions::Uniform;

        let mut rng = rand::thread_rng();
        let uniform_dist = Uniform::new_inclusive(Gf256Elm::min_value(), Gf256Elm::max_value());

        let x: Gf256Elm = rng.sample(&uniform_dist);
        println!("x = {:?}", x);

        let xs: Vec<Gf256Elm> = rng.sample_iter(&uniform_dist).take(8).collect();
        println!("xs = {:?}", xs);
    }

    proptest! {
        #[test]
        fn prop_finite_field(x: u8, y: u8, z: u8) {
            let g = Gf256Elm::from(x);
            let h = Gf256Elm::from(y);
            let i = Gf256Elm::from(z);

            // Identity
            assert_eq!(g + Gf256Elm::zero(), g);
            assert_eq!(g * Gf256Elm::one(), g);

            // Inversity
            assert_eq!(g + (-g), Gf256Elm::zero());
            if !Gf256Elm::is_zero(&g) {
                assert_eq!(g * g.inv(), Gf256Elm::one());
            }

            // `Neg` and `Inv`, in addition
            assert_eq!(-g, Gf256Elm::zero() - g);
            if !Gf256Elm::is_zero(&g) {
                assert_eq!(g.inv(), Gf256Elm::one() / g);
            }

            // Associativity
            assert_eq!(g + h, h + g);
            assert_eq!(g * h, h * g);

            // Commutativity
            assert_eq!((g + h) + i, g + (h + i));
            assert_eq!((g * h) * i, g * (h * i));

            // Distributivity
            assert_eq!((g + h) * i, g * i + h * i);
        }
    }
}
