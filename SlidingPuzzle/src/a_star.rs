//! A\* search algorithm

use std::cmp::{Ordering, Reverse};
use std::collections::{HashMap, HashSet};

use super::{Node, SearchProblem, Solver};

use keyed_priority_queue::{KeyedPriorityQueue, Entry};

const DEFAULT_SIZE_HINT: usize = 8194;

pub struct AStar {
    size_hint: usize,
    node_count: usize,
}

impl Default for AStar {
    fn default() -> Self {
        AStar {
            size_hint: DEFAULT_SIZE_HINT,
            node_count: 0,
        }
    }
}

impl AStar {
    pub fn with_size_hint(size_hint: usize) -> Self {
        Self {
            size_hint,
            node_count: 0,
        }
    }

    fn reconstruct_path<T: Node>(start: &T, goal: &T, parents: HashMap<T, T>) -> Vec<T> {
        let mut curr = goal;
        let mut path = Vec::new();
        while curr != start {
            path.push(curr.clone());
            curr = &parents[curr];
        }
        path.reverse();
        path
    }
}

#[derive(Clone, Eq, Ord)]
struct Score {
    cost: i64,
    heuristic: i64,
}

impl PartialEq for Score {
    fn eq(&self, other: &Self) -> bool {
        self.cost + self.heuristic == other.cost + other.heuristic
    }
}

impl PartialOrd for Score {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some((self.cost + self.heuristic).cmp(&(other.cost + other.heuristic)))
    }
}

impl Solver for AStar {
    fn solve<T, S>(&mut self, problem: &S) -> Option<Vec<T>>
        where T: Node, S: SearchProblem<T>
    {
        self.node_count = 0;
        let start = problem.start();
        let goal = problem.goal();
        if let Some(false) = S::is_solvable(start, goal) {
            return None;
        }

        let mut open_set = KeyedPriorityQueue::with_capacity(self.size_hint);
        let score = Score {
            cost: 0,
            heuristic: problem.heuristic(start),
        };
        open_set.push(start.clone(), Reverse(score));
        let mut closed_set = HashSet::with_capacity(1024);

        let mut parents = HashMap::with_capacity(1024);

        while let Some((x, Reverse(curr_score))) = open_set.pop() {
            self.node_count += 1;
            if x == *goal {
                return Some(Self::reconstruct_path(start, goal, parents));
            }

            for neighbor in x.neighbors() {
                if closed_set.contains(&neighbor) {
                    continue;
                }

                let g = curr_score.cost + 1;
                let h = problem.heuristic(&neighbor);
                match open_set.entry(neighbor) {
                    Entry::Vacant(v) => {
                        let score = Score {
                            cost: g,
                            heuristic: h,
                        };
                        parents.insert(v.get_key().clone(), x.clone());
                        v.set_priority(Reverse(score));
                    }
                    Entry::Occupied(o) => {
                        let Reverse(old_score) = o.get_priority();
                        if g < old_score.cost {
                            let score = Score {
                                cost: g,
                                heuristic: old_score.heuristic,
                            };
                            parents.insert(o.get_key().clone(), x.clone());
                            o.set_priority(Reverse(score));
                        }
                    }
                }
            }
            closed_set.insert(x);
        }
        None
    }

    fn node_count(&self) -> Option<usize> {
        Some(self.node_count)
    }
}
