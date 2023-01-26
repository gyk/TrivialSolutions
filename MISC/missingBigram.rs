//! # Missing Bigram
//!
//! - https://codeforces.com/problemset/problem/1618/B
//! - https://alphacode.deepmind.com/#problem=138

use std::io::{self, prelude::*};

fn solve<B: BufRead, W: Write>(mut scan: Scanner<B>, mut w: W) {
    let t: usize = scan.token();

    for _ in 0..t {
        let n: usize = scan.token();

        let mut bigrams = Vec::<(u8, u8)>::with_capacity(n - 2);

        for _ in 0..(n - 2) {
            let bigram: String = scan.token();
            let fst = bigram.as_bytes()[0];
            let snd = bigram.as_bytes()[1];
            bigrams.push((fst, snd));
        }

        let mut output = String::with_capacity(n);
        for i in 0..(bigrams.len() - 1) {
            output.push(bigrams[i].0 as char);
            if bigrams[i].1 != bigrams[i + 1].0 {
                output.push(bigrams[i].1 as char);
            }
        }
        output.push(bigrams[bigrams.len() - 1].0 as char);
        output.push(bigrams[bigrams.len() - 1].1 as char);

        if output.len() < n {
            output.push('a');
        }

        writeln!(w, "{}", output).unwrap();
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
