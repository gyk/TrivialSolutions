use std::collections::{BTreeMap, BTreeSet};

use crate::graph::*;

/// Converts SCCs in list representation into a set of SCC sets.
pub fn scc_list_to_set(scc_list: &[usize]) -> BTreeSet<BTreeSet<usize>> {
    let mut mapping = BTreeMap::<usize, BTreeSet<usize>>::new();
    for (i, &x) in scc_list.iter().enumerate() {
        mapping.entry(x).or_insert_with(|| BTreeSet::new()).insert(i);
    }
    use std::iter::FromIterator;
    BTreeSet::from_iter(mapping.into_iter().map(|(_, v)| v))
}

pub fn strong_reach(scc_list: &[usize], u: usize, v: usize) -> bool {
    scc_list[u] == scc_list[v]
}

// ===== Kosaraju's algorithm =====
//
// https://en.wikipedia.org/wiki/Kosaraju%27s_algorithm

// (From Wikipedia)
//
// - It makes use of the fact that the transpose graph has exactly the same SCC as the original one.
// - During the first traversal, it does not matter whether a vertex v was first visited because it
//   appeared in the enumeration of all vertices or because it was the out-neighbour of another
//   vertex u that got visited.
//
// - - - -
//
// How this algorithm works: Let `F(u)` (`B(u)`) be the the set of vertices reachable from `u` by
// forward (backward) traversal, `u ⇒ v` (`u ⇏ v`) denotes `v` is reachable (unreachable) from `u`,
// for a vertex pair of `u` and `v`:
//
// 1. u ⇏ v & v ⇏ u    ⟺    v ∈ ∁(F(u) ∪ B(u))
// 2. u ⇒ v & v ⇏ u    ⟺    v ∈ F(u) \ B(u)
// 3. u ⇏ v & v ⇒ u    ⟺    v ∈ B(u) \ F(u)
// 4. u ⇒ v & v ⇒ u    ⟺    v ∈ F(u) ∩ B(u)
//
// In Case 2, `v` always appears before `u` in the postorder list (either be first enumerated, or
// set in DFS), while in Case 3, `u` always appears before `v`. In Case 1, since either is related
// to the other, their positions on the postorder list just depends on the enumerating order. Case 4
// implies `u` and `v` belongs to the same SCC, which is exactly what we are interested in.
//
// Note that when only out-neighbors are stored, given `u`, it is difficult to query "whether there
// exists any `v` that `v ⇒ u`?". As a result, the first DFS has to be run on the reverse graph (so
// the query can be rephrased as "find any `v` that `u ⇒ v`"). The implementation here takes this
// way, so it differs from the one from Wikipedia.
//
// So in the 1st pass, we build the postorder list of the **reverse** graph. Let
//
//     FB(u) = B(u) ∩ F(u), FB1(u) ∪ FB2(u) = FB(u),
//
// We have (since Case 1 is irrelevent, they are not shown for brevity):
//
//     Postorder(R) list = [ (B(u) \ F(u)) ∪ FB1(u)) | u | (F(u) \ B(u)) ∪ FB2(u) ]
//
// And let `P(u)` be those appear strictly **after** `u` on the postorder list of `reverse(G)`,
//
//     SCC(u) = F(u) ∩ B(u) = F(u) \ (F(u) \ B(u))
//
// Futhermore, we can simply compute `SCC(u)` as `F(u) \ P(u)` because if `FB2(u)` is not empty, `u`
// has already been handled in `u ∈ FB1(v)` when processing `v`, where `v ∈ FB1(u)`. Essentially,
// this means `u` and `v` are in the same SCC and we visit `v` first.


/// Computes strongly connected component using Kosaraju's algorithm.
pub fn scc_kosaraju(g: &Graph) -> Vec<usize> {
    // ----- Pass 1 -----

    // The postorder list of the reverse graph
    let postorder_list = {
        let mut postorder_list = Vec::with_capacity(g.n_nodes());
        let g_rev = g.transpose();
        g_rev.dfs(|_| (), |n| postorder_list.push(n));
        postorder_list
    };

    // ----- Pass 2 -----
    let mut scc_list: Vec<Option<usize>> = vec![None; g.n_nodes()];
    let mut visited = vec![false; g.n_nodes()];
    for &n in postorder_list.iter().rev() {
        if !visited[n] {
            let root = n;
            g.dfs_r(
                n,
                &mut |n| {
                    assert!(scc_list[n].is_none());
                    scc_list[n] = Some(root);
                },
                &mut |_| (),
                &mut visited,
            );
        }
    }

    scc_list.into_iter().collect::<Option<_>>().expect("scc_kosaraju error")
}

// ===== Tarjan's algorithm =====
//
// https://en.wikipedia.org/wiki/Tarjan%27s_strongly_connected_components_algorithm

struct SccTarjanContext<'a> {
    g: &'a Graph,
    scc_list: Vec<Option<usize>>,

    preorder: usize,
    preorder_list: Vec<Option<usize>>,
    low_list: Vec<Option<usize>>,
    stack: Vec<usize>,
}

impl<'a> SccTarjanContext<'a> {
    pub fn new(g: &'a Graph) -> Self {
        let n_nodes = g.n_nodes();

        Self {
            g,
            scc_list: vec![None; n_nodes],

            preorder: 0,
            preorder_list: vec![None; n_nodes],
            low_list: vec![None; n_nodes],
            stack: Vec::new(),
        }
    }
}

/// Computes strongly connected component using Tarjan's algorithm.
pub fn scc_tarjan(g: &Graph) -> Vec<usize> {
    // Can't be expressed with the general DFS routine.
    fn scc_tarjan_dfs_r(ctx: &mut SccTarjanContext, n: usize) {
        assert!(ctx.preorder_list[n].is_none());
        ctx.preorder_list[n] = Some(ctx.preorder);

        assert!(ctx.low_list[n].is_none());
        ctx.low_list[n] = Some(ctx.preorder);
        let mut lowest = ctx.preorder;

        ctx.preorder += 1;
        ctx.stack.push(n);

        let mut maybe_next_e = ctx.g.nodes[n].outgoing_edges;
        while let Some(e) = maybe_next_e {
            let m = ctx.g.edges[e].to_node;

            if ctx.preorder_list[m].is_none() {
                scc_tarjan_dfs_r(ctx, m);
            }

            // At this point, node m should have been visited. So if `low_list[m]` is `None`, edge
            // n-m must be a cross-edge, and m is no longer on stack. In this case, we should ignore
            // it.
            //
            // Also note that in the original paper, when a back edge is met, `low_list[n]` is
            // assigned to `min(low_list[n], preorder_list[m])`. It means `low_list[n]` only takes
            // into account nodes reachable through the nodes in the DFS subtree of n. This choice
            // affects the following case (7 ⇢ 2) but the result is the same.
            //
            //     6 ⇠ 5
            //     ⇣   ⇡
            //     7 ⇢ 2 ⇢ 3
            //         ⇡   ⇣
            //         1 ⇠ 4
            //         ⇡
            //         0
            //
            if let Some(l) = ctx.low_list[m] {
                lowest = ::std::cmp::min(lowest, l);
            }

            maybe_next_e = ctx.g.edges[e].next_edge;
        }

        if lowest < ctx.low_list[n].unwrap() {
            ctx.low_list[n] = Some(lowest);
            return;
        }

        while let Some(m) = ctx.stack.pop() {
            ctx.scc_list[m] = Some(n);
            ctx.low_list[m] = None; // Marks it as "not on stack".

            if m == n {
                break;
            }
        }
    }

    let mut ctx = SccTarjanContext::new(&g);
    for n in 0..g.n_nodes() {
        if ctx.preorder_list[n].is_none() {
            scc_tarjan_dfs_r(&mut ctx, n);
        }
    }

    ctx.scc_list.into_iter().collect::<Option<_>>().expect("scc_tarjan error")
}

// ===== Gabow's algorithm =====
//
// https://en.wikipedia.org/wiki/Path-based_strong_component_algorithm

struct SccGabowContext<'a> {
    g: &'a Graph,
    scc_list: Vec<Option<usize>>,

    preorder: usize,
    preorder_list: Vec<Option<usize>>,
    stack: Vec<usize>, // stack S
    path: Vec<usize>, // stack P
}

impl<'a> SccGabowContext<'a> {
    pub fn new(g: &'a Graph) -> Self {
        let n_nodes = g.n_nodes();

        Self {
            g,
            scc_list: vec![None; n_nodes],

            preorder: 0,
            preorder_list: vec![None; n_nodes],
            stack: Vec::new(),
            path: Vec::new(),
        }
    }
}

/// Computes strongly connected component using Gabow's algorithm.
pub fn scc_gabow(g: &Graph) -> Vec<usize> {
    // Can't be expressed with the general DFS routine.
    fn scc_gabow_dfs_r(ctx: &mut SccGabowContext, n: usize) {
        assert!(ctx.preorder_list[n].is_none());
        ctx.preorder_list[n] = Some(ctx.preorder);
        ctx.preorder += 1;
        ctx.stack.push(n);
        ctx.path.push(n);

        let mut maybe_next_e = ctx.g.nodes[n].outgoing_edges;
        while let Some(e) = maybe_next_e {
            let m = ctx.g.edges[e].to_node;

            if ctx.preorder_list[m].is_none() {
                scc_gabow_dfs_r(ctx, m);
            } else if ctx.scc_list[m].is_none() {
                // Node m has been visited, but not yet assigned to a SCC. Therefore it must be in
                // the `path`, and all the nodes locate above m in the `path` stack belong to the
                // same SCC as m.
                //
                // "When a back edge shows that a sequence of such vertices all belong to the same
                // strong component, we pop that stack to leave only the destination vertex of the
                // back edge, which is nearer the root of the tree than are any of the other
                // vertices." (from Sedgewick's book)
                while let Some(&p) = ctx.path.last() {
                    if ctx.preorder_list[p].unwrap() > ctx.preorder_list[m].unwrap() {
                        ctx.path.pop();
                    } else {
                        break;
                    }
                }
            }

            maybe_next_e = ctx.g.edges[e].next_edge;
        }

        match ctx.path.last() {
            Some(&p) if p == n => { ctx.path.pop(); }
            _ => return, // has been popped, ignored.
        }

        while let Some(m) = ctx.stack.pop() {
            ctx.scc_list[m] = Some(n);

            if m == n {
                break;
            }
        }
    }

    let mut ctx = SccGabowContext::new(&g);
    for n in 0..g.n_nodes() {
        if ctx.preorder_list[n].is_none() {
            scc_gabow_dfs_r(&mut ctx, n);
        }
    }

    ctx.scc_list.into_iter().collect::<Option<_>>().expect("scc_gabow error")
}

#[cfg(test)]
mod tests {
    use super::*;

    fn make_graph() -> Graph {
        // Algorithm in C, Part 5, Figure 19.28
        let mut g = Graph::with_capacity(13, 22);
        g.add_nodes(13);

        g.add_edge(0, 1);
        g.add_edge(0, 5);
        g.add_edge(0, 6);
        g.add_edge(2, 0);
        g.add_edge(2, 3);
        g.add_edge(3, 2);
        g.add_edge(3, 5);
        g.add_edge(4, 2);
        g.add_edge(4, 3);
        g.add_edge(4, 11);
        g.add_edge(5, 4);
        g.add_edge(6, 4);
        g.add_edge(6, 9);
        g.add_edge(7, 6);
        g.add_edge(7, 8);
        g.add_edge(8, 7);
        g.add_edge(8, 9);
        g.add_edge(9, 10);
        g.add_edge(9, 11);
        g.add_edge(10, 12);
        g.add_edge(11, 12);
        g.add_edge(12, 9);

        g
    }

    #[test]
    fn kosaraju() {
        let g = make_graph();
        let scc_list = scc_kosaraju(&g);
        let scc_set = scc_list_to_set(&scc_list);
        println!("{:#?}", scc_set);
    }

    #[test]
    fn tarjan() {
        let g = make_graph();
        let scc_list = scc_tarjan(&g);
        let scc_set = scc_list_to_set(&scc_list);
        println!("{:#?}", scc_set);
    }

    #[test]
    fn gabow() {
        let g = make_graph();
        let scc_list = scc_gabow(&g);
        let scc_set = scc_list_to_set(&scc_list);
        println!("{:#?}", scc_set);
    }

    #[test]
    fn random_scc() {
        let g = Graph::random(50, 0.05);
        let scc_kosaraju = scc_list_to_set(&scc_kosaraju(&g));
        let scc_tarjan = scc_list_to_set(&scc_tarjan(&g));
        let scc_gabow = scc_list_to_set(&scc_gabow(&g));
        assert_eq!(scc_kosaraju, scc_tarjan);
        assert_eq!(scc_tarjan, scc_gabow);
    }
}
