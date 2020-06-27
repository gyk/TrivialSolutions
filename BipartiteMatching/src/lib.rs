//! # Maximum-cardinality bipartite matching using Kuhn's algorithm
//!
//! (Is this algorithm a special case of Hungarian/Kuhn-Munkres algorithm?)
//!
//! ## References
//!
//! - https://cs.stackexchange.com/q/115411

use std::iter::Iterator;

use rand::{thread_rng, seq::SliceRandom};

/// Maximum-cardinality bipartite matching
pub struct BipartiteMatch {
    l2r: Vec<Option<usize>>,
    r2l: Vec<Option<usize>>,
    cardinality: Option<usize>,
}

// https://cs.stackexchange.com/a/42407/
//
// Kuhn's algorithm maintains the following invariant: after scanning through vertices 𝑣1,…,𝑣𝑘 on
// the left, the current matching is a maximal matching of the graph consisting of 𝑣1,…,𝑣𝑘 on the
// left, and the entire right-hand side. Hence at the end, we get a maximal matching of the entire
// graph.

impl BipartiteMatch {
    /// `graph`: the l -> &[r] mapping
    pub fn new(n_l: usize, n_r: usize, graph: &dyn for<'a> Graph<'a>) -> Self {
        let mut bm = BipartiteMatch {
            l2r: vec![None; n_l],
            r2l: vec![None; n_r],
            cardinality: None,
        };

        bm.bipartite_match(graph);
        bm
    }

    #[allow(dead_code)]
    pub fn l2r_match(&self) -> &[Option<usize>] {
        &self.l2r
    }

    #[allow(dead_code)]
    pub fn r2l_match(&self) -> &[Option<usize>] {
        &self.r2l
    }

    pub fn cardinality(&self) -> usize {
        self.cardinality.expect("Unset cardinality")
    }

    // Tries to find an augmenting path by DFS. In this context, *augmenting path* refers to an
    // alternating path that starts and ends in unmatched vertices. For a bipartite match M and an
    // augmenting path P, M' = M ⊕ P, we have |M'| = |M| + 1. (In other words, "inversing" the edges
    // in the path will increase the match size by 1.)
    //
    // The implementation does the augmenting along the way of unwinding the DFS stack. `seen` is
    // used to indicate whether the left node has appeared somewhere down the stack (i.e., it's been
    // included in the current partial path). If the function returns true, it means an augmenting
    // path is found and `l` must be matched.
    fn kuhn_dfs(&mut self, l: usize, seen: &mut[bool], graph: &dyn for<'a> Graph<'a>) -> bool {
        if seen[l] {
            return false;
        }
        seen[l] = true;

        let r_list: &[usize] = graph.node_list(l);
        let mut indices = (0..r_list.len()).collect::<Vec<_>>();
        indices.shuffle(&mut thread_rng());

        for i in indices {
            let r = r_list[i];
            // If `l` has already been matched to `r`, it will goes to the 2nd branch and
            // `can_assign` must be false because `l` has been visited. The `!seen[old_l]` is not
            // necessary but it saves us a function call.
            let can_assign = match self.r2l[r] {
                None => true, // The recursion ends here (so the last one is a free node)
                Some(old_l) => !seen[old_l] && self.kuhn_dfs(old_l, seen, graph),
            };

            if can_assign {
                self.l2r[l] = Some(r);
                self.r2l[r] = Some(l);
                return true;
            }
        }

        false
    }

    fn bipartite_match(&mut self, graph: &dyn for<'a> Graph<'a>) {
        let n_l = self.l2r.len();
        let mut seen = vec![false; n_l];
        let mut count = 0;

        loop {
            seen.iter_mut().for_each(|b| *b = false);
            let old_count = count;
            for l in 0..n_l {
                if self.l2r[l].is_none() {
                    if self.kuhn_dfs(l, &mut seen, graph) {
                        count += 1;
                    }
                }
            }
            if count == old_count {
                break;
            }
        }
        self.cardinality = Some(count);

        debug_assert_eq!(
            self.cardinality.unwrap(),
            self.l2r.iter().filter(|x| x.is_some()).count());
        debug_assert_eq!(
            self.cardinality.unwrap(),
            self.r2l.iter().filter(|x| x.is_some()).count());
    }
}

// - https://users.rust-lang.org/t/22652
// - https://doc.rust-lang.org/beta/nomicon/hrtb.html.
// - https://github.com/rust-lang/rfcs/blob/master/text/1598-generic_associated_types.md
pub trait Graph<'a> {
    // Returns a slice instead of an Iterator for supporting randomization.
    fn node_list(&'a self, node: usize) -> &'a [usize];
}

use std::collections::btree_map::*;

pub struct BTreeMapGraph(pub BTreeMap<usize, Vec<usize>>);

impl<'a> Graph<'a> for BTreeMapGraph {
    fn node_list(&'a self, node: usize) -> &'a [usize] {
        self.0.get(&node).map(AsRef::as_ref).unwrap_or(&[])
    }
}


#[cfg(test)]
mod tests {
    use super::*;

    use std::collections::HashSet;
    use std::iter::Iterator;
    use rand::Rng;

    #[test]
    fn smoke() {
        let mut graph = BTreeMap::<usize, Vec<usize>>::new();
        graph.insert(0, vec![1, 2]);
        graph.insert(1, vec![0, 3]);
        graph.insert(2, vec![2]);
        graph.insert(3, vec![2, 3]);
        graph.insert(5, vec![5]);

        let bm = BipartiteMatch::new(6, 6, &BTreeMapGraph(graph));
        assert_eq!(bm.cardinality(), 5);

        let mut graph = BTreeMap::<usize, Vec<usize>>::new();
        graph.insert(0, vec![1]);
        graph.insert(1, vec![1]);
        graph.insert(2, vec![0]);
        graph.insert(3, vec![2, 3]);
        graph.insert(4, vec![1]);

        let bm = BipartiteMatch::new(5, 4, &BTreeMapGraph(graph));
        assert_eq!(bm.cardinality(), 3);

        let mut graph = BTreeMap::<usize, Vec<usize>>::new();
        graph.insert(0, vec![1, 3]);
        graph.insert(1, vec![0, 2]);
        graph.insert(2, vec![1, 3]);
        graph.insert(3, vec![1, 3]);

        let bm = BipartiteMatch::new(4, 4, &BTreeMapGraph(graph));
        assert_eq!(bm.cardinality(), 3);

        let mut graph = BTreeMap::<usize, Vec<usize>>::new();
        graph.insert(0, vec![0, 1, 3]);
        graph.insert(1, vec![0, 1, 3, 4]);
        graph.insert(2, vec![2]);
        graph.insert(3, vec![2]);
        graph.insert(4, vec![1, 2, 3, 4]);

        let bm = BipartiteMatch::new(5, 5, &BTreeMapGraph(graph));
        assert_eq!(bm.cardinality(), 4);

        let mut graph = BTreeMap::<usize, Vec<usize>>::new();
        graph.insert(0, vec![0, 1]);
        graph.insert(1, vec![0, 2]);
        graph.insert(2, vec![1, 3]);
        graph.insert(3, vec![1, 2]);

        let bm = BipartiteMatch::new(4, 4, &BTreeMapGraph(graph));
        assert_eq!(bm.cardinality(), 4);

        let mut graph = BTreeMap::<usize, Vec<usize>>::new();
        graph.insert(0, vec![0, 1]);
        graph.insert(1, vec![0, 4]);
        graph.insert(2, vec![2, 3]);
        graph.insert(3, vec![0, 4]);
        graph.insert(4, vec![0, 3]);

        let bm = BipartiteMatch::new(5, 5, &BTreeMapGraph(graph));
        assert_eq!(bm.cardinality(), 5);
    }

    #[test]
    fn one_to_one() {
        let mut graph = BTreeMap::<usize, Vec<usize>>::new();
        const N: usize = 50;
        for i in 0..N {
            graph.insert(i, vec![i]);
        }
        let bm = BipartiteMatch::new(N, N, &BTreeMapGraph(graph));
        assert_eq!(bm.cardinality(), N);
    }

    #[test]
    fn complete() {
        let mut graph = BTreeMap::<usize, Vec<usize>>::new();
        const N: usize = 25;
        const M: usize = 20;
        let all = (0..M).collect::<Vec<_>>();
        for i in 0..N {
            graph.insert(i, all.clone());
        }
        let bm = BipartiteMatch::new(N, M, &BTreeMapGraph(graph));
        assert_eq!(bm.cardinality(), std::cmp::min(M, N));
    }

    fn random_bipartite_graph(n_l: usize, n_r: usize, mut n_e: usize) -> BTreeMapGraph {
        let mut graph = BTreeMap::<usize, Vec<usize>>::new();
        let mut edge_set = HashSet::<(usize, usize)>::new();

        let mut rng = thread_rng();
        assert!(n_e <= n_l * n_r);
        while n_e > 0 {
            let l = rng.gen_range(0, n_l);
            let r = rng.gen_range(0, n_r);
            let e = (l, r);
            if edge_set.contains(&e) {
                continue;
            }
            n_e -= 1;
            edge_set.insert(e);
        }

        for (l, r) in edge_set {
            let edges = match graph.entry(l) {
                Entry::Vacant(v) => v.insert(vec![]),
                Entry::Occupied(o) => o.into_mut(),
            };
            edges.push(r);
        }

        BTreeMapGraph(graph)
    }

    fn randomized_one(n_l: usize, n_r: usize, n_e: usize) {
        let graph = random_bipartite_graph(n_l, n_r, n_e);

        // We don't know the answer, but if the code is correct, each run should produce the
        // identical number.
        let same = (0..10)
            .map(|_| BipartiteMatch::new(n_l, n_r, &graph).cardinality())
            .collect::<Vec<_>>()
            .windows(2)
            .all(|w| w[0] == w[1]);
        assert!(same);
    }

    #[test]
    fn randomized() {
        for _ in 0..3 {
            randomized_one(5, 5, 5);
            randomized_one(20, 30, 100);
            randomized_one(40, 50, 500);
            randomized_one(100, 100, 2000);
            randomized_one(50, 40, 20);
        }
    }
}
