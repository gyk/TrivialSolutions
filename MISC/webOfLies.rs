//! # Web of Lies
//!
//! Failed (time limit exceeded)
//!
//! - https://codeforces.com/problemset/problem/1548/A
//! - https://alphacode.deepmind.com/#problem=1

use std::collections::HashSet;
use std::io::{self, prelude::*};

fn solve<B: BufRead, W: Write>(mut scan: Scanner<B>, mut w: W) {
    let n: usize = scan.token();
    let m: usize = scan.token();

    let mut web = vec![HashSet::new(); n];

    fn read_pair<B: BufRead>(scan: &mut Scanner<B>) -> (usize, usize) {
        let u: usize = scan.token();
        let v: usize = scan.token();
        if u > v {
            (v, u)
        } else {
            (u, v)
        }
    }

    for _ in 0..m {
        let (u, v) = read_pair(&mut scan);
        web[u].insert(v);
    }

    let q: usize = scan.token();
    for _ in 0..q {
        let t: usize = scan.token();
        match t {
            1 => {
                let (u, v) = read_pair(&mut scan);
                web[u].insert(v);
            }
            2 => {
                let (u, v) = read_pair(&mut scan);
                web[u].remove(&v);
            }
            3 => {
                let n_killed = web.iter().filter(|s| !s.is_empty()).count();
                writeln!(w, "{}", n - n_killed).unwrap();
                let _ = w.flush();
            }
            _ => unreachable!(),
        }
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
