use std::fmt;
use std::hash::{Hash, Hasher};
use std::iter::Iterator;

use lazy_static::lazy_static;

mod a_star;
pub use a_star::AStar;

mod bidirectional;
pub use bidirectional::Bidirectional;

const N: usize = 3; // 8-Puzzle

pub trait Node: Clone + Eq + Hash {
    fn neighbors(&self) -> Vec<Self>;
}

#[derive(Clone, Eq)]
pub struct Board {
    tiles: [u8; N * N],
    blank: usize,
}

impl Board {
    pub fn from(tiles: [u8; N * N]) -> Option<Self> {
        let mut seen = vec![false; N * N];
        let mut blank: Option<usize> = None;
        for i in 0 .. (N * N) {
            let t = tiles[i] as usize;
            if t >= N * N || seen[t] {
                return None;
            }
            if t == 0 {
                blank = Some(i);
            }
            seen[t] = true;
        }

        if seen.iter().all(|&b| b) {
            if let Some(blank) = blank {
                let board = Board {
                    tiles,
                    blank,
                };
                return Some(board);
            }
        }
        None
    }

    pub fn inversions(&self) -> usize {
        let mut inversions = 0;
        let len = self.tiles.len();
        for i in 0..len {
            for j in (i + 1)..len {
                if self.tiles[i] == 0 || self.tiles[j] == 0 {
                    continue;
                }

                if self.tiles[i] > self.tiles[j] {
                    inversions += 1;
                }
            }
        }
        inversions
    }

    pub fn as_factorial(&self) -> usize {
        let len = self.tiles.len();
        let mut x = 0;
        for i in 0..len {
            let base = FACTORIALS[len - 1 - i];
            for j in (i + 1)..len {
                if self.tiles[i] > self.tiles[j] {
                    x += base;
                }
            }
        }
        x
    }
}

impl Default for Board {
    fn default() -> Self {
        let mut tiles = [0; N * N];
        for i in 1 ..= (N * N - 1) {
            tiles[i - 1] = i as u8;
        }
        Board {
            tiles,
            blank: 8,
        }
    }
}

impl fmt::Display for Board {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        for r in 0 .. (N as isize) {
            for c in 0 .. (N as isize) {
                write!(f, "{:>2} ", self.tiles[rc2i((r, c)).unwrap()])?;
            }
            writeln!(f)?;
        }
        writeln!(f)?;
        Ok(())
    }
}

lazy_static! {
    static ref NEIGHBORS: Vec<Vec<usize>> = {
        let mut a = (0 .. (N * N)).map(|_| vec![]).collect::<Vec<Vec<usize>>>();
        for i in 0 .. (N * N) {
            let (r, c) = i2rc(i);
            if let Some(left) = rc2i((r, c - 1)) {
                a[i].push(left);
            }
            if let Some(up) = rc2i((r - 1, c)) {
                a[i].push(up);
            }
            if let Some(right) = rc2i((r, c + 1)) {
                a[i].push(right);
            }
            if let Some(down) = rc2i((r + 1, c)) {
                a[i].push(down);
            }
        }
        a
    };

    // Manhattan distances
    static ref DISTANCES: Vec<Vec<isize>> = {
        let mut distances: Vec<Vec<isize>> = (0 .. (N * N))
            .map(|_| vec![0; N * N])
            .collect();
        for i1 in 0 .. (N * N) {
            let row = &mut distances[i1];
            let (r1, c1) = i2rc(i1);
            for i2 in 0 .. (N * N) {
                let (r2, c2) = i2rc(i2);
                row[i2] = (r1 - r2).abs() + (c1 - c2).abs();
            }
        }
        distances
    };

    // FIXME: Overflow?
    static ref FACTORIALS: Vec<usize> = (1..)
        .scan(1, |acc, x| Some(std::mem::replace(acc, *acc * x)))
        .take(N * N)
        .collect();
}

#[inline]
fn i2rc(i: usize) -> (isize, isize) {
    debug_assert!(i < N * N);
    ((i / N) as isize, (i % N) as isize)
}

fn rc2i((r, c): (isize, isize)) -> Option<usize> {
    if r < 0 || c < 0 {
        return None;
    }
    let (r, c) = (r as usize, c as usize);
    if r >= N || c >= N {
        None
    } else {
        Some(r * N + c)
    }
}

impl Hash for Board {
    fn hash<H: Hasher>(&self, state: &mut H) {
        let mut h = 0;
        let base = N * N;
        for &x in self.tiles.iter() {
            h = h * base + x as usize;
        }
        h.hash(state)
    }
}

impl PartialEq for Board {
    fn eq(&self, other: &Self) -> bool {
        self.tiles == other.tiles
    }
}

impl Node for Board {
    fn neighbors(&self) -> Vec<Board> {
        let mut res = vec![];
        for &neighbor in &NEIGHBORS[self.blank] {
            let mut brd = self.clone();
            brd.tiles[self.blank] = brd.tiles[neighbor];
            brd.tiles[neighbor] = 0;
            brd.blank = neighbor;
            res.push(brd);
        }
        res
    }
}

pub trait Solver {
    /// Returns `None` if there is no solution.
    fn solve<T: Node, S: SearchProblem<T>>(&mut self, problem: &S) -> Option<Vec<T>>;

    /// How many nodes (states) have been expanded in total?
    fn node_count(&self) -> Option<usize> {
        None
    }
}

/// The problem definition
pub trait SearchProblem<T: Node> {
    fn start(&self) -> &T;
    fn goal(&self) -> &T;
    fn heuristic(&self, node: &T) -> i64;

    /// Returns `None` if unable to confirm.
    fn is_solvable(_start: &T, _goal: &T) -> Option<bool> {
        None
    }
}

pub struct SlidingPuzzle {
    start: Board,
    goal: Board,
    goal_inv: Vec<usize>,
}

impl SlidingPuzzle {
    pub fn new(start: Board, goal: Board) -> Self {
        let mut goal_inv = vec![0; N * N];
        for i in 0 .. (N * N) {
            goal_inv[goal.tiles[i] as usize] = i;
        }

        SlidingPuzzle {
            start,
            goal,
            goal_inv,
        }
    }
}

impl SearchProblem<Board> for SlidingPuzzle {
    fn start(&self) -> &Board { &self.start }
    fn goal(&self) -> &Board { &self.goal }

    fn heuristic(&self, board: &Board) -> i64 {
        let mut h = 0;
        for (i, &x) in board.tiles.iter().enumerate() {
            if x == 0 {
                continue;
            }
            h += DISTANCES[i][self.goal_inv[x as usize]];
        }
        h as i64
    }

    fn is_solvable(start: &Board, goal: &Board) -> Option<bool> {
        let parity = if N % 2 == 0 {
            start.blank / N + start.inversions() + goal.blank / N + goal.inversions()
        } else {
            start.inversions() + goal.inversions()
        };
        Some(parity % 2 == 0)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    use rand::seq::SliceRandom;
    use rand::thread_rng;

    #[test]
    fn test_factorial() {
        let mut board = Board::default();

        board.tiles[0 .. (N * N - 1)].reverse();
        assert_eq!(board.as_factorial(), FACTORIALS.last().unwrap() * (N * N) - 1);

        board.tiles.reverse();
        board.blank = 0;
        assert_eq!(board.as_factorial(), 0);
    }

    #[test]
    fn test_check_solution() {
        let mut rng = thread_rng();
        let goal = Board::default();

        for _ in 0..10 {
            let board = {
                let mut board = Board::default();
                board.tiles[0 .. (N * N - 1)].shuffle(&mut rng);
                assert!(SlidingPuzzle::is_solvable(&board, &board).unwrap());
                let mut board_bad = board.clone();
                board_bad.tiles.swap(N * N - 3, N * N - 2);
                assert!(!SlidingPuzzle::is_solvable(&board_bad, &board).unwrap());

                let mut tiles = board.tiles;
                tiles.shuffle(&mut rng);
                Board::from(tiles).unwrap()
            };
            let is_solvable = SlidingPuzzle::is_solvable(&board, &goal).unwrap();

            for neighbor in board.neighbors() {
                assert!(SlidingPuzzle::is_solvable(&neighbor, &goal).unwrap() == is_solvable);
            }
        }
    }

    #[test]
    fn test_solver() {
        // Test cases borrowed from:
        // https://www.cs.princeton.edu/courses/archive/spring20/cos226/assignments/8puzzle/checklist.php
        let goal = Board::default();

        let puzzles = vec![
            [
                1, 2, 3,
                4, 5, 6,
                7, 8, 0,
            ],
            [
                1, 2, 3,
                4, 5, 0,
                7, 8, 6,
            ],
            [
                1, 2, 3,
                4, 0, 5,
                7, 8, 6,
            ],
            [
                1, 2, 3,
                0, 4, 5,
                7, 8, 6,
            ],
            [
                0, 1, 2,
                4, 5, 3,
                7, 8, 6,
            ],
            [
                1, 0, 2,
                4, 6, 3,
                7, 5, 8,
            ],
            [
                1, 2, 0,
                4, 8, 3,
                7, 6, 5,
            ],
            [
                1, 2, 3,
                0, 4, 8,
                7, 6, 5,
            ],
            [
                0, 4, 3,
                2, 1, 6,
                7, 5, 8,
            ],
            [
                1, 3, 6,
                5, 2, 8,
                4, 0, 7,
            ],
            [
                0, 4, 1,
                5, 3, 2,
                7, 8, 6,
            ],
            [
                1, 3, 5,
                7, 2, 6,
                8, 0, 4,
            ],
            [
                4, 1, 2,
                3, 0, 6,
                5, 7, 8,
            ],
            [
                4, 3, 1,
                0, 7, 2,
                8, 5, 6,
            ],
            [
                3, 4, 6,
                2, 0, 8,
                1, 7, 5,
            ],
            [
                2, 0, 8,
                1, 3, 5,
                4, 6, 7,
            ],
            [
                5, 2, 1,
                4, 8, 3,
                7, 6, 0,
            ],
            [
                4, 3, 1,
                0, 2, 6,
                7, 8, 5,
            ],
            [
                1, 4, 3,
                7, 0, 8,
                6, 5, 2,
            ],
            [
                7, 0, 4,
                8, 5, 1,
                6, 3, 2,
            ],
            [
                7, 4, 3,
                2, 8, 6,
                0, 5, 1,
            ],
            [
                8, 7, 2,
                1, 5, 0,
                4, 6, 3,
            ],
            [
                5, 3, 6,
                4, 0, 7,
                1, 8, 2,
            ],
            [
                6, 0, 8,
                4, 3, 5,
                1, 2, 7,
            ],
            [
                6, 5, 3,
                4, 1, 7,
                0, 2, 8,
            ],
            [
                8, 3, 5,
                6, 4, 2,
                1, 0, 7,
            ],
            [
                4, 8, 7,
                5, 3, 1,
                0, 6, 2,
            ],
            [
                1, 6, 4,
                0, 3, 5,
                8, 2, 7,
            ],
            [
                6, 3, 8,
                5, 4, 1,
                7, 2, 0,
            ],
            [
                1, 8, 5,
                0, 2, 4,
                3, 6, 7,
            ],
            [
                8, 6, 7,
                2, 0, 4,
                3, 5, 1,
            ],
            [
                6, 4, 7,
                8, 5, 0,
                3, 2, 1,
            ]
        ];

        let mut a_star_solver = AStar::default();
        let mut bd_solver = Bidirectional::default();
        for (n_steps, tiles) in puzzles.into_iter().enumerate() {
            let start = Board::from(tiles).unwrap();
            let puzzle = SlidingPuzzle::new(start, goal.clone());
            let a_star_solution = a_star_solver.solve(&puzzle);
            let bd_solution = bd_solver.solve(&puzzle);
            assert_eq!(a_star_solution.unwrap().len(), n_steps);
            assert_eq!(bd_solution.unwrap().len(), n_steps);
            println!("#nodes expanded: A* = {}, BD = {}",
                a_star_solver.node_count().unwrap_or(0),
                bd_solver.node_count().unwrap_or(0));
        }
    }
}
