// SGU 118 - Digital Root
use std::io::{self, prelude::*};

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

fn dr(x: u32) -> u32 {
    if x == 0 {
        0
    } else {
        let d = x % 9;
        if d == 0 {
            9
        } else {
            d
        }
    }
}

fn digital_root(a: Vec<u32>) -> u32 {
    dr(
        a
        .iter()
        .scan(1, |p, &x| {
            let x = dr(x);
            *p = dr((*p) * x);
            Some(*p)
        })
        .sum()
    )
}

fn solve<B: BufRead, W: Write>(mut scan: Scanner<B>, mut w: W) {
    let k: usize = scan.token();
    for _ in 0..k {
        let n: usize = scan.token();
        let mut a = Vec::with_capacity(n);
        for _ in 0..n {
            let x: u32 = scan.token();
            a.push(x);
        }
        writeln!(w, "{}", digital_root(a)).expect("failed write");
        w.flush().expect("failed flush"); // not necessary?
    }
}

fn main() {
    let stdin = io::stdin();
    let stdout = io::stdout();
    let reader = Scanner::new(stdin.lock());
    let writer = io::BufWriter::new(stdout.lock());
    solve(reader, writer);
}
