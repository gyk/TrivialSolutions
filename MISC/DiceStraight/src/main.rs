// Dice Straight (Google Code Jam 2017 Finals, Problem A)
// https://code.google.com/codejam/contest/6314486/dashboard#s=p0

use std::io::{self, prelude::*};
use std::cmp;
use std::collections::btree_map::*;

use rand::{thread_rng, seq::SliceRandom};

// Maximum-cardinality bipartite matching
struct BipartiteMatch<'a> {
    u2v: Vec<Option<usize>>,
    v2u: Vec<Option<usize>>,
    edges: &'a BTreeMap<usize, Vec<usize>>, // v -> [u] mapping
    seen: Vec<bool>,
}

impl<'a> BipartiteMatch<'a> {
    pub fn new(n_u: usize, n_v: usize, edges: &'a BTreeMap<usize, Vec<usize>>) -> Self {
        Self {
            u2v: vec![None; n_u],
            v2u: vec![None; n_v],
            edges,
            seen: vec![false; n_v],
        }
    }

    // Every vertex in set V must be matched
    pub fn add_v(&mut self, v: usize) -> bool {
        self.seen.iter_mut().for_each(|b| *b = false);
        self.kuhn_dfs(v)
    }

    fn kuhn_dfs(&mut self, v: usize) -> bool {
        self.seen[v] = true;

        for &u in &self.edges[&v] {
            let can_assign = match self.u2v[u] {
                None => true,
                Some(old_v) => !self.seen[old_v] && self.kuhn_dfs(old_v),
            };

            if can_assign {
                self.u2v[u] = Some(v);
                self.v2u[v] = Some(u);
                return true;
            }
        }

        false
    }

    pub fn remove_v(&mut self, v: usize) {
        if let Some(u) = self.v2u[v].take() {
            // This slot is set free so `kuhn_dfs(v)` will never be called again.
            self.u2v[u].take();
        }
    }

    pub fn shuffle(edges: &mut BTreeMap<usize, Vec<usize>>) {
        let mut rng = thread_rng();
        for (_, v_list) in edges {
            v_list.shuffle(&mut rng);
        }
    }
}

fn dice_straight(dices: &Vec<Vec<usize>>) -> usize {
    let mut face_dice_map = BTreeMap::<usize, Vec<usize>>::new();

    let n_dices = dices.len();
    for d in 0..n_dices {
        for &face in &dices[d] {
            match face_dice_map.entry(face) {
                Entry::Vacant(v) => {
                    v.insert(vec![d]);
                }
                Entry::Occupied(ref mut o) => {
                    o.get_mut().push(d);
                }
            }
        }
    }

    BipartiteMatch::shuffle(&mut face_dice_map);

    let mut length = 0;
    let mut matcher = BipartiteMatch::new(n_dices, 1_000_000 + 1, &face_dice_map);
    let mut l;
    let mut r = 0;
    loop {
        l = match face_dice_map.range(r..).next() {
            Some((&l, _)) => l,
            None => break,
        };
        r = l;

        loop {
            if !face_dice_map.contains_key(&r) {
                (l..r).for_each(|i| matcher.remove_v(i));
                break;
            }
            if !matcher.add_v(r) {
                matcher.remove_v(l);
                l += 1;
                continue;
            }
            r += 1;
            length = cmp::max(length, r - l);
        }
    }

    length
}

fn solve<B: BufRead, W: Write>(mut scan: Scanner<B>, mut w: W) {
    let n_tests: usize = scan.token();
    for i in 1..=n_tests {
        let n_dices: usize = scan.token();
        let mut dices = vec![vec![0; 6]; n_dices];
        for d in 0..n_dices {
            for face in 0..6 {
                dices[d][face] = scan.token();
            }
        }

        writeln!(w, "Case #{}: {}", i, dice_straight(&dices)).expect("write error");
        w.flush().unwrap();
    }
}

// ===== IO =====
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
