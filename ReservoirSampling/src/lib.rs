//! # Weighted reservoir sampling
//!
//! Generate weighted random samples in one-pass over unknown populations.
//!
//! ## References
//!
//! - Efraimidis, Pavlos S., and Paul G. Spirakis. "Weighted Random Sampling with a Reservoir."
//!   Information Processing Letters, vol. 97, no. 5, 2006, pp. 181–185.
//! - <https://en.wikipedia.org/wiki/Reservoir_sampling#Weighted_Random_Sampling_using_Reservoir>

extern crate rand;

mod ord_wrapper;

use std::collections::BinaryHeap;
use std::ops::Neg;

use rand::Rng;

use ord_wrapper::OrdWrapper;

// Adapter for min heap
trait PriorityQueueKey {
    fn to_pq_key(self) -> Self;
    fn from_pq_key(self) -> Self;
}

impl PriorityQueueKey for f32 {
    fn to_pq_key(self) -> Self {
        self.neg()
    }

    fn from_pq_key(self) -> Self {
        self.neg()
    }
}

pub struct WeightedReservoirSampler<T> {
    reservoir: BinaryHeap<OrdWrapper<T>>,
    n_samples: usize,
}

impl<T> WeightedReservoirSampler<T> {
    pub fn new(n_samples: usize) -> WeightedReservoirSampler<T> {
        Self {
            reservoir: BinaryHeap::with_capacity(n_samples),
            n_samples: n_samples,
        }
    }

    pub fn append(&mut self, item: T, weight: f32) {
        let mut rng = rand::thread_rng();
        // log(rand(0, 1) ^ (1/w))
        let w: f32 = rng.gen::<f32>().log2() / weight;

        let wrapped_item = OrdWrapper {
            key: w.to_pq_key(),
            value: item,
        };

        // Extends reservoir sampling with random sort
        if self.reservoir.len() < self.n_samples {
            self.reservoir.push(wrapped_item);
        } else {
            match self.reservoir.peek_mut() {
                Some(mut m) => {
                    let min_weight = m.key.from_pq_key();
                    if min_weight < w {
                        *m = wrapped_item;
                    }
                }
                None => unreachable!(),
            }
        }
    }

    pub fn take(self) -> Vec<T> {
        self.reservoir
            .into_iter()
            .map(|x| x.value)
            .collect()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn smoke() {
        use rand::distributions::{Weighted, WeightedChoice, IndependentSample};

        let data = (0..100)
            .map(|i| {
                let w = i * i;
                (w, i)
            })
            .collect::<Vec<_>>();

        let mut wrs = WeightedReservoirSampler::new(10);
        data.iter()
            .for_each(|&(w, i)| {
                wrs.append(i, w as f32);
            });

        println!("Sampled values: {:?}", wrs.take());

        // ===== By `rand` =====
        let mut data_for_rand = data
            .iter()
            .map(|&(w, i)| {
                Weighted { weight: w, item: i }
            })
            .collect::<Vec<_>>();
        let wc = WeightedChoice::new(&mut data_for_rand);
        let mut rng = rand::thread_rng();
        let sampled = (0..10)
            .map(|i| {
                wc.ind_sample(&mut rng)
            })
            .collect::<Vec<_>>();
        println!("Sampled values by `rand`: {:?}", sampled);
    }
}
