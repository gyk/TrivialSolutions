//! # Web of Lies
//!
//! Failed, time limit exceeded
//!
//! - https://codeforces.com/problemset/problem/1548/A
//! - https://alphacode.deepmind.com/#problem=1

use std::collections::{btree_map::Entry, BTreeMap, BTreeSet};
use std::io::{self, prelude::*};

type Web = BTreeMap<usize, BTreeSet<usize>>;

fn add_friends(web: &mut Web, u: usize, v: usize) {
    fn add_friends_impl(web: &mut Web, u: usize, v: usize) {
        match web.entry(u) {
            Entry::Vacant(vac) => {
                let singleton = BTreeSet::from_iter(vec![v]);
                vac.insert(singleton);
            }
            Entry::Occupied(mut o) => {
                o.get_mut().insert(v);
            }
        }
    }

    add_friends_impl(web, u, v);
    add_friends_impl(web, v, u);
}

fn remove_friends(web: &mut Web, u: usize, v: usize) {
    fn remove_friends_impl(web: &mut Web, u: usize, v: usize) {
        match web.entry(u) {
            Entry::Vacant(..) => (),
            Entry::Occupied(mut o) => {
                o.get_mut().remove(&v);
            }
        }
    }

    remove_friends_impl(web, u, v);
    remove_friends_impl(web, v, u);
}

#[allow(dead_code)]
fn process(mut web: Web) -> usize {
    fn process_impl(web: &mut Web, starts_from: usize) -> Option<usize> {
        for (u, friends) in web.range(starts_from..) {
            if let Some(lowest_friend) = friends.iter().next() {
                if lowest_friend > u {
                    return Some(*u);
                }
            }
        }
        None
    }

    let mut starts_from = 1;

    let mut n_killed = 0;
    while let Some(killed) = process_impl(&mut web, starts_from) {
        starts_from = killed + 1;
        if let Some(friends) = web.remove(&killed) {
            n_killed += 1;
            for f in friends {
                remove_friends(&mut web, f, killed);
            }
        }
    }
    n_killed
}

fn process2(web: &Web) -> usize {
    let mut n_killed = 0;
    for (u, friends) in web.iter() {
        if friends.range((u + 1)..).next().is_some() {
            n_killed += 1;
        }
    }
    n_killed
}

fn solve<B: BufRead, W: Write>(mut scan: Scanner<B>, mut w: W) {
    let n: usize = scan.token();
    let m: usize = scan.token();

    let mut web = Web::new();

    for _ in 0..m {
        let u: usize = scan.token();
        let v: usize = scan.token();
        add_friends(&mut web, u, v);
    }

    let q: usize = scan.token();
    for _ in 0..q {
        let t: usize = scan.token();
        match t {
            1 => {
                let u: usize = scan.token();
                let v: usize = scan.token();
                add_friends(&mut web, u, v);
            }
            2 => {
                let u: usize = scan.token();
                let v: usize = scan.token();
                remove_friends(&mut web, u, v);
            }
            3 => {
                let n_killed = process2(&web);
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
