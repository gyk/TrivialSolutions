//! # The Three Little Pigs
//!
//! Failed, time limit exceeded
//!
//! - https://codeforces.com/problemset/problem/1548/C
//! - https://alphacode.deepmind.com/#problem=5

use std::io::{self, prelude::*};

const MOD: usize = 1_000_000_000 + 7;
const N: usize = 1_000_000;

struct Combinator {
    m: usize,
    facts: Vec<usize>,
    inv_facts: Vec<usize>,
}

impl Combinator {
    pub fn new(max_n: usize, m: usize) -> Self {
        let mut facts = vec![1; max_n + 1];
        let mut invs = vec![1; max_n + 1];
        let mut inv_facts = vec![1; max_n + 1];
        for i in 2..=max_n {
            facts[i] = facts[i - 1] * i % m;
            // https://cp-algorithms.com/algebra/module-inverse.html#finding-the-modular-inverse-using-extended-euclidean-algorithm
            invs[i] = (m - m / i) * invs[m % i] % m;
            inv_facts[i] = inv_facts[i - 1] * invs[i] % m;
        }

        Combinator {
            m,
            facts,
            inv_facts,
        }
    }

    pub fn get(&self, n: usize, r: usize) -> Option<usize> {
        let fact_n = self.facts.get(n)?;
        let inv_fact_n_minu_r = self.inv_facts.get(n - r)?;
        let inv_fact_r = self.inv_facts.get(r)?;
        Some(((fact_n * inv_fact_n_minu_r) % self.m * inv_fact_r) % self.m)
    }
}

fn solve<B: BufRead, W: Write>(mut scan: Scanner<B>, mut w: W) {
    let n: usize = scan.token();
    let q: usize = scan.token();

    let combinator = Combinator::new(N, MOD);

    for _ in 0..q {
        let x: usize = scan.token();

        let mut n_plans = 0;

        for minute in 1..=n {
            if 3 * minute >= x {
                n_plans += combinator.get(3 * minute, x).unwrap() % MOD;
            }
        }

        writeln!(w, "{}", n_plans).unwrap();
        let _ = w.flush();
    }
}

pub struct Scanner<R> {
    reader: R,
    buffer: Vec<String>,
}

impl<R: io::BufRead> Scanner<R> {
    pub fn new(reader: R) -> Self {
        Self {
            reader,
            buffer: Vec::new(),
        }
    }

    pub fn token<T: std::str::FromStr>(&mut self) -> T {
        loop {
            if let Some(token) = self.buffer.pop() {
                return token.parse().ok().expect("failed parse");
            }
            let mut input = String::new();
            self.reader.read_line(&mut input).expect("failed read");
            self.buffer = input.split_whitespace().rev().map(String::from).collect();
        }
    }
}

fn main() {
    let stdin = io::stdin();
    let stdout = io::stdout();
    let reader = Scanner::new(stdin.lock());
    let writer = io::BufWriter::new(stdout.lock());
    solve(reader, writer);
}
