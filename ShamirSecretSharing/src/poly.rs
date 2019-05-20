//! Polynomial

// There already exists a `polynomial` crate but I have to roll my own because of
// <https://github.com/gifnksm/polynomial-rs/issues/4>.

use std::fmt;
use std::iter::FromIterator;

use num::{Zero, One};
use num_traits::{Bounded, NumOps};
use rand::Rng;
use rand::distributions::{Uniform, uniform::SampleUniform};

// The coefficients are arranged in reversed order ($a_0$ is the first item).
#[derive(PartialEq)]
pub struct Polynomial<T: PartialEq>(Vec<T>);

impl<T: fmt::Debug + PartialEq> fmt::Debug for Polynomial<T> {
    fn fmt(&self, fmt: &mut fmt::Formatter) -> fmt::Result {
        fmt.debug_tuple("Polynomial").field(&self.0).finish()
    }
}

impl<T> Polynomial<T>
    where T: SampleUniform + Bounded + One + PartialEq
{
    /// Generates a random monic polynomial, with the given constant term.
    ///
    /// # Parameters
    ///
    /// - `n`: The number of terms of the polynomial. Note that `n` is degree - 1.
    /// - `constant_term`: The constant term of generated polynomial.
    pub fn random_monic_with_const<R: Rng>(rng: &mut R, n: usize, constant_term: T) -> Self {
        if n < 2 {
            panic!("`n` (degree + 1) must be at least 2");
        }

        let uniform_dist: Uniform<T> = Uniform::new_inclusive(T::min_value(), T::max_value());

        let mut p = Polynomial::from_iter(rng
            .sample_iter(&uniform_dist)
            .take(n));

        p.0.first_mut().map(|coeff| *coeff = constant_term);
        p.0.last_mut().map(|coeff| *coeff = T::one());

        p
    }
}

impl<T> Polynomial<T>
    where T: NumOps + Zero + One + Copy + PartialEq
{
    /// Evaluates the polynomial at `x` using Horner's rule.
    pub fn eval_at(&self, x: T) -> T {
        self.0
            .iter()
            .rev()
            .fold(T::zero(), |acc, &v| {
                acc * x + v
            })
    }

    /// Computes the constant term using Lagrange interpolation.
    ///
    /// <https://en.wikipedia.org/wiki/Shamir%27s_Secret_Sharing#Computationally_efficient_approach>
    pub fn lagrange_interpolate_y(points: &[(T, T)]) -> T {
        let mut c = T::zero();
        for (i, &(x, y)) in points.iter().enumerate() {
            let mut l = T::one();
            for (j, &(xx, _)) in points.iter().enumerate() {
                if j != i {
                    l = l * xx / (x - xx) ;
                }
            }
            c = c + y * l
        }
        c
    }
}

impl<T: PartialEq> FromIterator<T> for Polynomial<T> {
    fn from_iter<I>(iter: I) -> Polynomial<T>
        where I: IntoIterator<Item = T>
    {
        Polynomial(iter.into_iter().collect::<Vec<_>>())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    use crate::gf256::Gf256Elm;

    macro_rules! gf_vec {
        ($elem:expr; $n:expr) => (gf_vec!(@collect vec![$elem; $n]));
        ($($x:expr),*) => (gf_vec!(@collect vec![$($x),*]));
        ($($x:expr,)*) => (gf_vec!(@collect vec![$($x),*]));

        (@collect $vec:expr) => {
            $vec.into_iter()
                .map(Gf256Elm::from)
                .collect::<Vec<_>>()
        };
    }

    #[test]
    fn test_poly_gen() {
        let mut rng = rand::thread_rng();
        let poly: Polynomial<Gf256Elm> = Polynomial::random_monic_with_const(
            &mut rng, 10, 42.into());
        println!("poly = {:?}", poly);
        assert_eq!(*poly.0.first().unwrap(), 42.into());
        assert_eq!(*poly.0.last().unwrap(), Gf256Elm::one());

        let dummy_poly = Polynomial::random_monic_with_const(&mut rng, 2, 0.into());
        assert_eq!(dummy_poly, Polynomial(gf_vec![0, 1]));
    }

    // Test cases borrowed from @codahale's implementation.
    #[test]
    fn test_poly_eval() {
        assert_eq!(Polynomial(Vec::new()).eval_at(0), 0);

        assert_eq!(
            Polynomial::from_iter(gf_vec![1, 0, 2, 3]).eval_at(2.into()),
            17.into()
        );
    }

    #[test]
    fn test_poly_interpolate() {
        assert_eq!(
            Polynomial::lagrange_interpolate_y(&
                gf_vec![1, 2, 3]
                    .into_iter()
                    .zip(gf_vec![1, 2, 3])
                    .collect::<Vec<_>>()),
            0.into()
        );

        assert_eq!(
            Polynomial::lagrange_interpolate_y(&
                gf_vec![1, 2, 3]
                    .into_iter()
                    .zip(gf_vec![80, 90, 20])
                    .collect::<Vec<_>>()),
            30.into()
        );

        assert_eq!(
            Polynomial::lagrange_interpolate_y(&
                gf_vec![1, 2, 3]
                    .into_iter()
                    .zip(gf_vec![43, 22, 86])
                    .collect::<Vec<_>>()),
            107.into()
        );
    }
}
