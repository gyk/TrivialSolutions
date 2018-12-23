//! Graph

use std::mem;

#[derive(Debug, Default)]
pub struct Node {
    pub(crate) outgoing_edges: Option<usize>,
}

#[derive(Debug)]
pub struct Edge {
    pub(crate) from_node: usize,
    pub(crate) to_node: usize,
    pub(crate) next_edge: Option<usize>,
}

#[derive(Debug)]
/// Represents a (directed) graph.
pub struct Graph {
    pub(crate) nodes: Vec<Node>,
    pub(crate) edges: Vec<Edge>,
}

impl Graph {
    pub fn with_capacity(n_nodes: usize, n_edges: usize) -> Self {
        Self {
            nodes: Vec::with_capacity(n_nodes),
            edges: Vec::with_capacity(n_edges),
        }
    }

    /// Generates random **directed** graph $G_{n, p}$ based on Erdős-Rényi model.
    pub fn random(n_nodes: usize, p: f64) -> Self {
        let n_edges_estimated = ((n_nodes * n_nodes) as f64 * p) as usize;
        let mut g = Graph::with_capacity(n_nodes, n_edges_estimated);
        g.add_nodes(n_nodes);

        for i in 0..n_nodes {
            for j in 0..n_nodes {
                let has_edge = i != j && rand::random::<f64>() < p;
                if has_edge {
                    g.add_edge(i, j);
                }
            }
        }

        g
    }

    pub fn n_nodes(&self) -> usize {
        self.nodes.len()
    }

    pub fn n_edges(&self) -> usize {
        self.edges.len()
    }

    /// Adds an orphan node, and returns its ID.
    pub fn add_node(&mut self) -> usize {
        self.nodes.push(Node::default());
        self.n_nodes() - 1
    }

    pub fn add_nodes(&mut self, n_nodes: usize) {
        for _ in 0..n_nodes {
            self.nodes.push(Node::default());
        }
    }

    /// Returns edge ID.
    pub fn add_edge(&mut self, from_node: usize, to_node: usize) -> usize {
        let mut new_e = Edge {
            from_node,
            to_node,
            next_edge: None,
        };
        let new_edge_id = self.n_edges();
        new_e.next_edge = mem::replace(&mut self.nodes[from_node].outgoing_edges,
            Some(new_edge_id));
        self.edges.push(new_e);
        new_edge_id
    }

    pub fn add_undirected_edge(&mut self, from_node: usize, to_node: usize) -> (usize, usize) {
        let e1 = self.add_edge(from_node, to_node);
        let e2 = self.add_edge(to_node, from_node);
        (e1, e2)
    }

    /// Computes the transpose graph.
    pub fn transpose(&self) -> Graph {
        let mut g = Graph::with_capacity(self.n_nodes(), self.n_edges());
        g.add_nodes(self.n_nodes());

        for n in &self.nodes {
            let mut maybe_next_e = n.outgoing_edges;
            while let Some(e) = maybe_next_e {
                g.add_edge(self.edges[e].to_node, self.edges[e].from_node);
                maybe_next_e = self.edges[e].next_edge;
            }
        }

        g
    }

    pub fn dfs<F1, F2>(&self,
                       mut pre_visitor: F1,
                       mut post_visitor: F2)
        where F1: FnMut(usize), F2: FnMut(usize)
    {
        let mut visited = vec![false; self.n_nodes()];
        for n in 0..self.n_nodes() {
            if !visited[n] {
                self.dfs_r(n, &mut pre_visitor, &mut post_visitor, &mut visited[..]);
            }
        }
    }

    pub(crate) fn dfs_r<F1, F2>(&self,
                                node: usize,
                                pre_visitor: &mut F1,
                                post_visitor: &mut F2,
                                visited: &mut [bool])
        where F1: FnMut(usize), F2: FnMut(usize)
    {
        if visited[node] {
            return;
        }
        visited[node] = true;

        pre_visitor(node);
        let mut maybe_next_e = self.nodes[node].outgoing_edges;
        while let Some(e) = maybe_next_e {
            let n = self.edges[e].to_node;
            if !visited[n] {
                self.dfs_r(n, pre_visitor, post_visitor, visited);
            }
            maybe_next_e = self.edges[e].next_edge;
        }
        post_visitor(node);
    }

    /// Exports Dot graph.
    pub fn dot(&self) -> String {
        let mut s = "digraph G {\n".to_owned();
        for n in 0..self.n_nodes() {
            let mut maybe_next_e = self.nodes[n].outgoing_edges;
            while let Some(e) = maybe_next_e {
                s.push_str(&format!("  {} -> {};\n", n, self.edges[e].to_node));
                maybe_next_e = self.edges[e].next_edge;
            }
        }
        s.push_str("}\n");
        s
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn smoke() {
        // Algorithm in C, Part 5, Figure 17.6
        let mut g = Graph::with_capacity(7, 8);
        g.add_nodes(7);

        g.add_edge(0, 1);
        g.add_edge(0, 2);
        g.add_edge(0, 5);
        g.add_edge(0, 6);
        g.add_edge(4, 3);
        g.add_edge(5, 3);
        g.add_edge(5, 4);
        g.add_edge(6, 4);

        println!("{}", g.dot());
        println!("\n================\n");
        println!("{}", g.transpose().dot());
    }

    #[test]
    fn print_random() {
        let g = Graph::random(10, 0.2);
        println!("{}", g.dot());
    }
}
