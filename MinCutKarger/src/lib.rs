//! Computes a minimum cut of an undirected connected graph using Karger's algorithm.

extern crate rand;

use std::collections::HashMap;
use std::collections::hash_map::Entry;
use std::cmp;
use std::mem;

use rand::distributions::{IndependentSample, Range};

pub type Vertex = usize;
pub type Weight = u32;

const UNIT_WEIGHT: Weight = 1_u32;
const MAX_WEIGHT: Weight = std::u32::MAX;

#[derive(Clone)]
pub struct Edge {
    vertex: Vertex,
    pub weight: Weight,
}

#[derive(Default, Clone)]
pub struct Graph {
    edges: HashMap<Vertex, Vec<Edge>>,
    n_vertices: usize,
    n_edges: usize,
}

impl Graph {
    pub fn add_edge(&mut self, from_vtx: Vertex, to_vtx: Vertex) {
        self.add_weighted_edge(from_vtx, to_vtx, UNIT_WEIGHT);
    }

    pub fn add_weighted_edge(&mut self, from_vtx: Vertex, to_vtx: Vertex, weight: Weight) {
        self.add_half_edge(from_vtx, to_vtx, weight);
        self.add_half_edge(to_vtx, from_vtx, weight);
        self.n_edges += 1;
    }

    #[inline]
    fn add_half_edge(&mut self, from_vtx: Vertex, to_vtx: Vertex, weight: Weight) {
        let adj = match self.edges.entry(from_vtx) {
            Entry::Occupied(adj_list) => adj_list.into_mut(),
            Entry::Vacant(vacant) => {
                self.n_vertices += 1;
                vacant.insert(Vec::new())
            }
        };

        let e = Edge {
            vertex: to_vtx,
            weight: weight,
        };
        adj.push(e);
    }

    pub fn n_vertices(&self) -> usize {
        self.n_vertices
    }

    pub fn find_random_edge(&self) -> (Vertex, Vertex) {
        let mut rng = rand::thread_rng();
        let edge_range = Range::new(0_usize, self.n_edges * 2);
        let mut i_edge = edge_range.ind_sample(&mut rng);

        debug_assert_eq!(self.n_edges * 2,
            self.edges
                .iter()
                .map(|(_, adj)| adj.len())
                .sum());

        for (&from_vtx, adj_list) in self.edges.iter() {
            if let Some(edge_to) = adj_list.get(i_edge) {
                let to_vtx = edge_to.vertex;
                return (from_vtx, to_vtx);
            } else {
                i_edge -= adj_list.len();
            }
        }

        unreachable!();
    }

    fn remove_all<T>(a: &mut Vec<T>, pred: &Fn(&T) -> bool) -> usize {
        let old_len = a.len();
        let mut l = old_len;
        let mut i = 0;
        while i < l {
            if pred(&a[i]) {
                a.swap_remove(i);
                l -= 1;
            } else {
                i += 1;
            }
        }
        old_len - l
    }

    pub fn contract_edge(&mut self, mut from_vtx: Vertex, mut to_vtx: Vertex) {
        assert!(from_vtx != to_vtx);
        if from_vtx > to_vtx {
            mem::swap(&mut from_vtx, &mut to_vtx);
        }

        let mut adj_list_to = self.edges.remove(&to_vtx).expect("`to_vtx` does not exist");
        let n_edges_removed = Self::remove_all(&mut adj_list_to,
            &|e: &Edge| e.vertex == from_vtx);


        // It's where the $O(V ^ 2)$ complexity comes from
        for e in adj_list_to.iter() {
            let v = e.vertex;
            let adj_v = self.edges.get_mut(&v).unwrap();
            for i in 0 .. adj_v.len() {
                if adj_v[i].vertex == to_vtx {
                    adj_v[i].vertex = from_vtx;
                }
            }
        }

        let mut adj_list_from = self.edges.get_mut(&from_vtx).expect("`from_vtx` does not exist");
        assert_eq!(Self::remove_all(&mut adj_list_from, &|e: &Edge| e.vertex == to_vtx),
            n_edges_removed);

        adj_list_from.extend(adj_list_to.into_iter());
        self.n_edges -= n_edges_removed;
        self.n_vertices -= 1;
    }

    /// Computes the repeating time at which the probability of not finding a minimum cut is no more
    /// than $1/n$.
    pub fn compute_repeating_time(&self) -> usize {
        // For an n-vertex graph, the probability to avoid min cut is:
        //
        // p_n >= 1 / choose(n, 2)

        let n = self.n_vertices as f32;
        (n * (n - 1.0) * n.log2() / 2.0).floor() as usize
    }

    pub fn min_cut_karger(graph: &Graph, n_trials: usize) -> Weight {
        let mut min_cut_so_far = MAX_WEIGHT;
        for _i in 0..n_trials {
            let mut graph = graph.clone();

            for _j in 0 .. graph.n_vertices - 2 {
                let (from_vtx, to_vtx) = graph.find_random_edge();
                graph.contract_edge(from_vtx, to_vtx);
            }

            graph.edges.iter().next().map(|(_from_vtx, adj_list)| {
                let weight_sum = adj_list
                    .iter()
                    .map(|e| e.weight)
                    .sum();
                min_cut_so_far = cmp::min(weight_sum, min_cut_so_far);
            });
        }

        min_cut_so_far
    }
}

#[allow(dead_code)]
fn min_cut_from_lines<I>(lines: I) -> Weight
    where I: Iterator<Item = String>
{
    let mut g = Graph::default();

    for l in lines {
        let inputs = l
            .split(' ')
            .map(|x| x.parse::<Vertex>().unwrap())
            .collect::<Vec<_>>();

        let from_vtx = inputs[0];
        let to_vtx = inputs[1];

        g.add_edge(from_vtx, to_vtx);
    }

    println!("n_edges = {}", g.n_edges);
    println!("sum(edges) = {}",
        g
            .edges
            .iter()
            .map(|(_, adj)| adj.len())
            .sum::<usize>());
    println!("n_vertices = {}\n", g.n_vertices);

    let repeating_time = g.compute_repeating_time();
    println!("Repeating time = {}", repeating_time);
    let m = Graph::min_cut_karger(&g, repeating_time);
    println!("Min cut = {}", m);
    m
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn smoke() {
        // The example from Wikipedia
        let s = [
            "1 2",
            "2 3",
            "3 4",
            "4 5",
            "1 3",
            "2 4",
            "3 5",
            "1 4",
            "2 5",
            "1 5",
            "11 12",
            "12 13",
            "13 14",
            "14 15",
            "11 13",
            "12 14",
            "13 15",
            "11 14",
            "12 15",
            "11 15",
            "1 11",
            "2 12",
            "3 13",
        ];

        assert_eq!(min_cut_from_lines(s.iter().map(|s| s.to_string())), 3);
    }
}
