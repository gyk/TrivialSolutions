// Solves discrete logarithm problem by "baby-step giant-step" algorithm.
// 
// 
// # References
//
// - <https://en.wikipedia.org/wiki/Baby-step_giant-step>
// - <http://blog.miskcoo.com/2015/05/discrete-logarithm-problem>

use std::io;
use std::io::prelude::*;
use std::collections::HashMap;

/// Finds `x` in
///
///     a^x = b (mod p)
///
/// given `a`, `b` and `p`.
pub fn baby_step_giant_step(a: u64, b: u64, p: u64) -> Option<u64> {
    let a = a % p;
    let mut b = b % p;
    let mut p = p;
    if b == 1 {
        return Some(0);
    }
    if p == 1 {
        return if b == 0 {
            // the smallest one
            Some(0)
        } else {
            None
        };
    }

    // `a` and `p` are not necessarily coprime. Since that
    //
    //     a^x = b (mod p) =>
    //     a^x + k*p = b
    //
    // let `q = gcd(a, p)`, we have:
    //
    //     a/q a^(x-1) + k p/q = b/q =>
    //     a/q a^(x-1) = b/q (mod p/q)
    //     a^(x-1) = b/q (a/q)^-1 (mod p/q)
    //
    // Just iterate until `q` = 1 and call the coprime version further, or `b/q == a/q` (which is
    // equivalent to `b == 1` in the original problem).
    let mut reduce_count = 0;
    let mut b_one = 1;
    loop {
        let q = gcd(p, a);
        if q == 1 {
            break;
        }
        {
            let b_over_q = b / q;
            if b_over_q * q != b {
                return None;
            } else {
                b = b_over_q;
            }
        }
        p /= q;
        reduce_count += 1;
        b_one *= a / q;
        b_one %= p;
        if b == b_one {
            return Some(reduce_count);
        }
    }

    bsgs_prime(a, b, p, Some(b_one)).map(|x| {
        x + reduce_count
    })
}

fn bsgs_prime(a: u64, b: u64, p: u64, b_div: Option<u64>) -> Option<u64> {
    let m = (p as f64).sqrt().ceil() as u64;
    let mut babies = HashMap::with_capacity(m as usize);
    let mut curr_baby = b;
    for j in 0..m {
        babies.insert(curr_baby, j);
        curr_baby = curr_baby * a % p;
    }

    // Here is a trick to avoid computing inversion:
    //
    // Rather than using:
    //
    //     x = i * m + j
    //     m = ceil(sqrt(n))
    //     b(a^(-m) ^ i)) = a^j, where 0 <= i < m, 0 <= j < m
    //
    // we use:
    //
    //     x = i * m - j
    //     m = ceil(sqrt(n))
    //     a^m ^ i = b * a^j, where 0 < i <= m+1, 0 <= j < m
    //
    // And for the non-coprime case, it becomes
    //
    //     (a^m ^ i) * b_div = b * a^j

    let giant_step = exp_mod(a, m, p);
    let mut giant = b_div.unwrap_or(1);
    for i in 1 .. (m + 1) + 1 {
        giant = giant * giant_step % p;
        if let Some(&j) = babies.get(&giant) {
            return Some(i * m - j);
        }
    }
    None
}

fn gcd(mut a: u64, mut b: u64) -> u64 {
    while b != 0 {
        let r = a % b;
        a = b;
        b = r;
    }
    a
}

// (base ^ exp) % mod
fn exp_mod(mut base: u64, mut exp: u64, m: u64) -> u64 {
    if m == 1 {
        return 0;
    }

    let mut res = 1;
    base %= m;
    while exp > 0 {
        if exp & 1 != 0 {
            res = res * base % m;
        }
        base = (base * base) % m;
        exp >>= 1;
    }
    res
}

fn main() {
    let stdin = io::stdin();

    for line in stdin.lock().lines() {
        let l = line.unwrap();
        let inputs = l.split(' ')
                      .map(|token| token.parse::<u64>().unwrap())
                      .collect::<Vec<_>>();
        let a = inputs[0];
        let b = inputs[2];
        let p = inputs[1];
        if a == 0 && b == 0 && p == 0 {
            break;
        }

        match baby_step_giant_step(a, b, p) {
            Some(i) => println!("{}", i),
            None => println!("No Solution"),
        }
    }
}
