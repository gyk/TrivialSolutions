use rand::Rng;
use num::Bounded;

pub use crate::gf256::Gf256Elm;
pub use crate::poly::Polynomial;

pub struct Shamir {
    n: usize,
    k: usize,

    force_reconstruction: bool,
}

impl Shamir {
    pub fn new(n: usize, k: usize) -> Self {
        if n > usize::from(u8::from(Gf256Elm::max_value())) {
            panic!("`n` is too large to present in GF(2^8)");
        }

        if k > n {
            panic!("`k` cannot be larger than `n`");
        }

        Self {
            n,
            k,

            force_reconstruction: false,
        }
    }

    pub fn set_force_reconstruction(&mut self, flag: bool) {
        self.force_reconstruction = flag;
    }

    /// Shares the secret to `n` people. Any subset of `k` people can reconstruct the secret.
    pub fn share_secret<R: Rng>(&self, rng: &mut R, secret: &[u8])
        -> Vec<(usize, Vec<Gf256Elm>)>
    {
        // Generates a random $k - 1$-degree polynomial for each byte of the secret.
        let polys = secret
            .iter()
            .map(|&x| Polynomial::random_monic_with_const(rng, self.k, x.into()))
            .collect::<Vec<_>>();

        (1 ..= self.n)
            .map(|id| {
                let share = polys.iter().map(|p| p.eval_at(Gf256Elm::from(id as u8))).collect();
                (id, share)
            })
            .collect()
    }

    pub fn reconstruct_secret<'a>(&self, shares: impl Iterator<Item = &'a (usize, Vec<Gf256Elm>)>)
        -> Option<Vec<u8>>
    {
        let mut shares = shares.peekable();
        let secret_len = {
            match shares.peek() {
                Some((_, share0)) => {
                    share0.len()
                }
                None => return None,
            }
        };

        let size_hint = {
            let size_hint = shares.size_hint().0;
            if size_hint > 0 {
                size_hint
            } else {
                self.k
            }
        };

        let mut points_list: Vec<Vec<(Gf256Elm, Gf256Elm)>> = (0..secret_len)
            .map(|_| Vec::with_capacity(size_hint))
            .collect();

        let mut n_shared = 0;
        for &(id, ref share) in shares {
            n_shared += 1;
            assert_eq!(share.len(), secret_len, "Inconsistent lengths of shared secrets");
            if id > usize::from(u8::from(Gf256Elm::max_value())) {
                panic!("`n` is too large to present in GF(2^8)");
            }
            let id = Gf256Elm::from(id as u8);

            for (i, &x) in share.iter().enumerate() {
                points_list[i].push((id, x));
            }
        }

        if n_shared < self.k && !self.force_reconstruction {
            return None;
        }

        Some(
            points_list.into_iter().map(|points|
                u8::from(Polynomial::lagrange_interpolate_y(&points))
            ).collect()
        )
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    use rand;
    use rand::seq::SliceRandom;

    #[test]
    fn test_ssss() {
        let alibaba_secret: &[u8] = b"Alibaba founder Jack Ma urges his employees and their \
            partners to have sex marathons every day";
        let k = 6;
        let n = 9;

        let mut rng = rand::thread_rng();
        let mut sss = Shamir::new(n, k);

        let alibaba_shares = sss.share_secret(&mut rng, alibaba_secret);
        assert_eq!(alibaba_shares.len(), n);

        let alibaba_candidates = alibaba_shares.choose_multiple(&mut rng, k);
        let unveiled = sss.reconstruct_secret(alibaba_candidates).expect("reconstruct failed");
        assert_eq!(&unveiled[..], alibaba_secret);

        // If one candidate is absent because he has been sent to ICU after a week of 996-669
        // work-sex marathon, we will not be able to reconstruct the secret.
        sss.set_force_reconstruction(true);
        let alibaba_candidates_one_in_icu = alibaba_shares.choose_multiple(&mut rng, k - 1);
        let failed = sss.reconstruct_secret(alibaba_candidates_one_in_icu).unwrap();
        assert!(&failed[..] != alibaba_secret);
    }
}
