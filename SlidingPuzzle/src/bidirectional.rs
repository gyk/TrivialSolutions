//! Bidirectional search (non-heuristic)
//!
//! Precondition: The `Node::neighbors()` method should be able to travel through the inverse arcs.

use std::collections::{HashMap, HashSet, VecDeque, hash_map::Entry};
use std::mem;

use super::{Node, SearchProblem, Solver};

const DEFAULT_SIZE_HINT: usize = 8194;

pub struct Bidirectional {
    size_hint: usize,
    node_count: usize,
}

impl Default for Bidirectional {
    fn default() -> Self {
        Bidirectional {
            size_hint: DEFAULT_SIZE_HINT,
            node_count: 0,
        }
    }
}

impl Bidirectional {
    fn reconstruct_path<T: Node>(start: &T, goal: &T, via: &T,
        src_parents: &HashMap<T, T>,
        dest_parents: &HashMap<T, T>,
    ) -> Vec<T> {
        let mut path = Vec::new();
        let mut x = via;
        while x != start {
            path.push(x.clone());
            x = &src_parents[&x];
        }
        path.reverse();
        x = via;
        while x != goal {
            x = &dest_parents[&x];
            path.push(x.clone());
        }
        path
    }
}

impl Solver for Bidirectional {
    fn solve<T, S>(&mut self, problem: &S) -> Option<Vec<T>>
        where T: Node, S: SearchProblem<T>
    {
        let mut src_queue = VecDeque::with_capacity(self.size_hint);
        let mut src_queue2 = VecDeque::with_capacity(self.size_hint);
        let mut dest_queue = VecDeque::with_capacity(self.size_hint);
        let mut dest_queue2 = VecDeque::with_capacity(self.size_hint);
        src_queue.push_back(problem.start().clone());
        dest_queue.push_back(problem.goal().clone());

        // Fringes
        let mut src_set = HashSet::with_capacity(self.size_hint);
        let mut dest_set = HashSet::with_capacity(self.size_hint);

        let mut src_parents = HashMap::with_capacity(self.size_hint);
        let mut dest_parents = HashMap::with_capacity(self.size_hint);

        while !(src_queue.is_empty() && dest_queue.is_empty()) {
            src_set.clear();
            while let Some(x) = src_queue.pop_front() {
                if dest_set.contains(&x) {
                    return Some(Bidirectional::reconstruct_path(problem.start(), problem.goal(), &x,
                        &src_parents, &dest_parents));
                }

                for neighbor in x.neighbors() {
                    match src_parents.entry(neighbor) {
                        Entry::Vacant(parent) => {
                            let neighbor = parent.key();
                            src_queue2.push_back(neighbor.clone());
                            src_set.insert(neighbor.clone());
                            parent.insert(x.clone());
                            self.node_count += 1;
                        }
                        _ => (),
                    }
                }

                src_set.insert(x);
            }
            mem::swap(&mut src_queue, &mut src_queue2);

            dest_set.clear();
            while let Some(x) = dest_queue.pop_front() {
                if src_set.contains(&x) {
                    return Some(Bidirectional::reconstruct_path(problem.start(), problem.goal(), &x,
                        &src_parents, &dest_parents));
                }

                for neighbor in x.neighbors() {
                    match dest_parents.entry(neighbor) {
                        Entry::Vacant(parent) => {
                            let neighbor = parent.key();
                            dest_queue2.push_back(neighbor.clone());
                            dest_set.insert(neighbor.clone());
                            parent.insert(x.clone());
                            self.node_count += 1;
                        }
                        _ => (),
                    }
                }

                dest_set.insert(x);
            }
            mem::swap(&mut dest_queue, &mut dest_queue2);
        }

        None
    }

    fn node_count(&self) -> Option<usize> {
        Some(self.node_count)
    }
}
