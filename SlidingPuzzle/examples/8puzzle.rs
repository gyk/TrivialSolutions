use std::io::{self, prelude::*};
use io::{Error, Result};

use sliding_puzzle::*;

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

fn read_board<B: BufRead>(scan: &mut Scanner<B>) -> Result<Board> {
    let mut tiles = [0_u8; 9];
    for i in 0..9 {
        tiles[i] = scan.token();
    }
    if let Some(board) = Board::from(tiles) {
        Ok(board)
    } else {
        Err(Error::new(io::ErrorKind::InvalidInput, "Invalid board"))
    }
}

fn main() -> Result<()> {
    let stdin = io::stdin();
    let mut reader = Scanner::new(stdin.lock());

    let start = read_board(&mut reader)?;
    let goal = read_board(&mut reader)?;

    let mut a_star_solver = AStar::default();
    let puzzle = SlidingPuzzle::new(start, goal);
    match a_star_solver.solve(&puzzle) {
        Some(solution) => {
            println!("The puzzle can be solved in {} step(s) with {} node(s) searched:\n",
                solution.len(),
                a_star_solver.node_count().map_or("unknown".into(), |x| format!("{}", x)));
            println!("START\n--------\n{}", puzzle.start());
            for i in 0..solution.len() {
                println!("STEP {}\n--------\n{}", i + 1, solution[i]);
            }
            println!();
        }
        None => println!("No solution.\n"),
    }

    Ok(())
}
