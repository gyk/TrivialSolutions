//! Computes hypotenuse, the robust way
//!
//! # Reference
//!
//! - Moler, Cleve, and Donald Morrison. "Replacing square roots by Pythagorean sums." IBM Journal
//!   of Research and Development 27.6 (1983): 577-581.
//!

use std::mem;
use std::io::{stdin, BufRead};

// This algorithm keeps `sqrt(x^2 + y^2)` invariant while increasing `x` and decreasing `y`. When
// `y` becomes numerically insignificant, `x` holds the desired result.
//
// To see the invariance holds, we know that (Here we suppose that `x != 0`, otherwise it's trivial
// to prove the correctness)
//
//     s = (y/x)^2 / (4 + (y/x)^2)
//
// Let $t = y / x$, dividing both sides by $x^2$, we have
//
//     L = ((x + 2*s*x)^2 + s^2 * y^2) / x^2
//       = (2 * t^2 / (4 + t^2) + 1)^2 + (t^2 / (4 + t^2))^2 * t^2
//
//     R = (x^2 + y^2) / x^2 = 1 + t^2
//
// Hence $L * (4 + t^2)^2 = t^6 + 9*t^4 + 24*t^2 + 16 = R * (4 + t^2)^2$.

/// Slow-but-safer way to compute `sqrt(x^2 + y^2)`.
pub fn hypot(mut x: f32, mut y: f32) -> f32 {
    if x < y {
        mem::swap(&mut x, &mut y);
    }

    let mut r = {
        let r = y / x;
        r * r
    };
    loop {
        let t = 4.0 + r;
        if t == 4.0 {
            break;
        }
        let s = r / t;
        x += 2.0 * s * x;
        y *= s;
        r = {
            let r = y / x;
            r * r
        };
    }
    x
}

fn hypot_naive(x: f32, y: f32) -> f32 {
    (x.powi(2) + y.powi(2)).sqrt()
}

fn main() {
    let stdin = stdin();
    for line in stdin.lock().lines() {
        let inputs = line
            .unwrap()
            .split(' ')
            .map(|x| x.parse::<f32>().unwrap())
            .collect::<Vec<_>>();
        let x = inputs[0];
        let y = inputs[1];
        // See if it overflows
        println!("Naive = {}, std::f32::hypot = {}, self::hypot = {}",
            hypot_naive(x, y), x.hypot(y), hypot(x, y));
    }
}
