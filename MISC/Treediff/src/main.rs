//! SGU 507 - Treediff

// FIXME: The code does NOT pass the tests on Codeforces (Verdict: Runtime error on test 5).
use std::cmp::min;
use std::collections::BTreeSet;
use std::io::{self, prelude::*};

const LEAF: i32 = i32::max_value();

// Borrowed from EbTech's code
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

#[derive(Debug)]
enum Node {
    Branch(Vec<usize>),
    Leaf(i32),
}

impl Node {
    pub fn new_branch() -> Node {
        Node::Branch(Vec::new())
    }
}

fn merge_min_diff(x1: (i32, BTreeSet<i32>), x2: (i32, BTreeSet<i32>)) -> (i32, BTreeSet<i32>) {
    let (mut x1, x2) = if x1.1.len() >= x2.1.len() {
        (x1, x2)
    } else {
        (x2, x1)
    };
    let (ref mut d1, ref mut s1) = x1;
    for v2 in x2.1.into_iter() {
        let v_lower = s1.range(..v2).next_back();
        let v_upper = s1.range(v2..).next();
        let d_lower = v_lower.map(|&v| v2.wrapping_sub(v)).unwrap_or(LEAF);
        let d_upper = v_upper.map(|&v| v.wrapping_sub(v2)).unwrap_or(LEAF);
        *d1 = min(*d1, min(d_lower, d_upper));
        s1.insert(v2);
    }
    x1
}

fn compute_min_diff(tree: &[Node], node_id: usize, output: &mut [i32]) -> (i32, BTreeSet<i32>) {
    match tree[node_id] {
        Node::Leaf(v) => {
            let mut s = BTreeSet::new();
            s.insert(v);
            (LEAF, s)
        }
        Node::Branch(ref children) => {
            let mut iter = children
                .iter()
                .map(|&n| compute_min_diff(tree, n, output));

            let s = iter.next().expect("empty branch");
            let s = iter.fold(s, |a, b| {
                merge_min_diff(a, b)
            });

            output[node_id] = s.0;
            s
        }
    }
}

fn solve<B: BufRead, W: Write>(mut scan: Scanner<B>, mut w: W) {
    let n: usize = scan.token();
    let m: usize = scan.token();

    let mut tree = Vec::<Node>::with_capacity(n + 1); // starts from 1
    tree.push(Node::Leaf(-1));
    tree.push(Node::new_branch());

    for i in 2..=n {
        let parent: usize = scan.token();
        match tree[parent] {
            Node::Branch(ref mut children) => {
                children.push(i);
            }
            Node::Leaf(..) => unreachable!("parent is a leaf"),
        }
        // "Leaves of the tree have numbers from n - m + 1 to n."
        if i < n - m + 1 {
            tree.push(Node::new_branch());
        };
    }

    for _ in 1..=m {
        tree.push(Node::Leaf(scan.token()));
    }

    let mut output = vec![0; 1 + n - m];
    compute_min_diff(&tree, 1, &mut output);

    let mut out_iter = output.into_iter();
    out_iter.next(); // index 0
    if let Some(v) = out_iter.next() {
        write!(w, "{}", v).expect("failed write");
        for v in out_iter {
            write!(w, " {}", v).expect("failed write");
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

#[cfg(test)]
mod tests {
    use super::*;

    const TEST1: &[u8] = include_bytes!("testdata/1.txt");
    const TEST2: &[u8] = include_bytes!("testdata/2.txt");
    const TEST3: &[u8] = include_bytes!("testdata/3.txt");
    const TEST4: &[u8] = include_bytes!("testdata/4.txt");

    fn check(testdata: &[u8], expected: &str) -> bool {
        let scan = Scanner::new(io::BufReader::new(testdata));
        let mut output = Vec::with_capacity(1024);
        solve(scan, &mut output);
        output == expected.as_bytes()
    }

    #[test]
    fn test1() {
        assert!(check(TEST1, "2"));
    }

    #[test]
    fn test2() {
        assert!(check(TEST2, "3"));
    }

    #[test]
    fn test3() {
        assert!(check(TEST3, "3 3 8"));
    }

    #[test]
    fn test4() {
        assert!(check(TEST4, "2147483647"));
    }
}
