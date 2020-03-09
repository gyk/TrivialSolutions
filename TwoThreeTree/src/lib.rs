//! 2-3 Tree in Rust
//!
//! <https://en.wikipedia.org/wiki/2–3_tree>

use std::cmp::Ordering;
use std::io::Write;

// TODO: Get rid of boilerplate code.
// TODO: Support key-value
// TODO: Deletion

// Trait bounds on struct? c.f. https://github.com/rust-lang/rust-clippy/issues/1689
pub struct TwoThreeTree<T: Ord> {
    root: Box<Node<T>>,
}

pub enum Node<T: Ord> {
    Leaf,
    Two {
        value: T,
        left: Box<Node<T>>,
        right: Box<Node<T>>,
    },
    Three {
        l_value: T,
        r_value: T,
        left: Box<Node<T>>,
        middle: Box<Node<T>>,
        right: Box<Node<T>>,
    },
}

/// Insertion result
enum InsRes<T: Ord> {
    Consumed(Box<Node<T>>),
    Pushed(T, Box<Node<T>>, Box<Node<T>>),
}

impl<T: Ord> Node<T> {
    pub fn leaf_boxed() -> Box<Self> {
        Box::new(Node::Leaf)
    }

    pub fn new2_boxed(value: T) -> Box<Self> {
        Box::new(Node::Two {
            value,
            left: Node::leaf_boxed(),
            right: Node::leaf_boxed(),
        })
    }

    pub fn new3_boxed(l_value: T, r_value: T) -> Box<Self> {
        Box::new(Node::Three {
            l_value,
            r_value,
            left: Node::leaf_boxed(),
            middle: Node::leaf_boxed(),
            right: Node::leaf_boxed(),
        })
    }

    pub fn is_leaf(&self) -> bool {
        match *self {
            Node::Leaf => true,
            _ => false,
        }
    }

    fn insert(self, x: T) -> InsRes<T> {
        match self {
            Node::Leaf => {
                InsRes::Consumed(Node::new2_boxed(x))
            }
            Node::Two { ref left, ref right, .. } if left.is_leaf() && right.is_leaf() => {
                let node = if let Node::Two { value, .. } = self {
                    match x.cmp(&value) {
                        Ordering::Equal => Node::new2_boxed(value),
                        Ordering::Less => Node::new3_boxed(x, value),
                        Ordering::Greater => Node::new3_boxed(value, x),
                    }
                } else {
                    unreachable!();
                };
                InsRes::Consumed(node)
            }
            Node::Two { .. } => {
                if let Node::Two { value, left, right } = self {
                    match x.cmp(&value) {
                        Ordering::Equal => {
                            InsRes::Consumed(Box::new(
                                Node::Two {
                                    value,
                                    left,
                                    right,
                                }
                            ))
                        }
                        Ordering::Less => {
                            match left.insert(x) {
                                InsRes::Consumed(left) => {
                                    InsRes::Consumed(Box::new(
                                        Node::Two {
                                            value,
                                            left,
                                            right,
                                        }
                                    ))
                                }
                                InsRes::Pushed(new_value, new_left, new_right) => {
                                    InsRes::Consumed(Box::new(
                                        Node::Three {
                                            l_value: new_value,
                                            r_value: value,
                                            left: new_left,
                                            middle: new_right,
                                            right,
                                        }
                                    ))
                                }
                            }
                        }
                        Ordering::Greater => {
                            match right.insert(x) {
                                InsRes::Consumed(right) => {
                                    InsRes::Consumed(Box::new(
                                        Node::Two {
                                            value,
                                            left,
                                            right,
                                        }
                                    ))
                                }
                                InsRes::Pushed(new_value, new_left, new_right) => {
                                    InsRes::Consumed(Box::new(
                                        Node::Three {
                                            l_value: value,
                                            r_value: new_value,
                                            left,
                                            middle: new_left,
                                            right: new_right,
                                        }
                                    ))
                                }
                            }
                        }
                    }
                } else {
                    unreachable!();
                }
            }
            Node::Three { ref left, ref middle, ref right, .. }
                if left.is_leaf() && middle.is_leaf() && right.is_leaf() =>
            {
                if let Node::Three { l_value, r_value, left, middle, right } = self {
                    if x == l_value || x == r_value {
                        InsRes::Consumed(Box::new(
                            Node::Three {
                                l_value,
                                r_value,
                                left,
                                middle,
                                right,
                            }
                        ))
                    } else {
                        let (l, m, r) = if x < l_value {
                            (x, l_value, r_value)
                        } else if x < r_value {
                            (l_value, x, r_value)
                        } else {
                            (l_value, r_value, x)
                        };
                        InsRes::Pushed(
                            m,
                            Node::new2_boxed(l),
                            Node::new2_boxed(r),
                        )
                    }
                } else {
                    unreachable!();
                }
            }
            Node::Three { .. } => {
                if let Node::Three { l_value, r_value, left, middle, right } = self {
                    if x == l_value || x == r_value {
                        InsRes::Consumed(Box::new(
                            Node::Three {
                                l_value,
                                r_value,
                                left,
                                middle,
                                right,
                            }
                        ))
                    } else if x < l_value {
                        match left.insert(x) {
                            InsRes::Consumed(left) => {
                                InsRes::Consumed(Box::new(
                                    Node::Three {
                                        l_value,
                                        r_value,
                                        left,
                                        middle,
                                        right,
                                    }
                                ))
                            }
                            InsRes::Pushed(new_value, new_left, new_right) => {
                                InsRes::Pushed(
                                    l_value,
                                    Box::new(Node::Two {
                                        value: new_value,
                                        left: new_left,
                                        right: new_right,
                                    }),
                                    Box::new(Node::Two {
                                        value: r_value,
                                        left: middle,
                                        right,
                                    }),
                                )
                            }
                        }
                    } else if x < r_value {
                        match middle.insert(x) {
                            InsRes::Consumed(middle) => {
                                InsRes::Consumed(Box::new(
                                    Node::Three {
                                        l_value,
                                        r_value,
                                        left,
                                        middle,
                                        right,
                                    }
                                ))
                            }
                            InsRes::Pushed(new_value, new_left, new_right) => {
                                InsRes::Pushed(
                                    new_value,
                                    Box::new(Node::Two {
                                        value: l_value,
                                        left,
                                        right: new_left,
                                    }),
                                    Box::new(Node::Two {
                                        value: r_value,
                                        left: new_right,
                                        right,
                                    }),
                                )
                            }
                        }
                    } else {
                        match right.insert(x) {
                            InsRes::Consumed(right) => {
                                InsRes::Consumed(Box::new(
                                    Node::Three {
                                        l_value,
                                        r_value,
                                        left,
                                        middle,
                                        right,
                                    }
                                ))
                            }
                            InsRes::Pushed(new_value, new_left, new_right) => {
                                InsRes::Pushed(
                                    r_value,
                                    Box::new(Node::Two {
                                        value: l_value,
                                        left,
                                        right: middle,
                                    }),
                                    Box::new(Node::Two {
                                        value: new_value,
                                        left: new_left,
                                        right: new_right,
                                    }),
                                )
                            }
                        }
                    }
                } else {
                    unreachable!();
                }
            }
        }
    }

    fn height(&self) -> usize {
        match *self {
            Node::Leaf => 0,
            Node::Two { ref left, ref right, .. } => {
                let l_height = left.height();
                let r_height = right.height();
                if l_height != r_height {
                    panic!("Invalid tree");
                }
                l_height + 1
            }
            Node::Three { ref left, ref middle, ref right, .. } => {
                let l_height = left.height();
                let m_height = middle.height();
                let r_height = right.height();
                if l_height != m_height || m_height != r_height {
                    panic!("Invalid tree");
                }
                l_height + 1
            }
        }
    }

    fn count(&self) -> usize {
        match *self {
            Node::Leaf => 0,
            Node::Two { ref left, ref right, .. } => {
                let l_count = left.count();
                let r_count = right.count();
                l_count + r_count + 1
            }
            Node::Three { ref left, ref middle, ref right, .. } => {
                let l_count = left.count();
                let m_count = middle.count();
                let r_count = right.count();
                l_count + m_count + r_count + 2
            }
        }
    }
}

impl<T: Ord + ToString> Node<T> {
    pub fn dot_graph<W: Write>(&self, id: &mut usize, wr: &mut W) -> Option<usize> {
        if self.is_leaf() {
            return None;
        }

        writeln!(wr, "  node{} [label=\"{}\"]", id, self.dot_label()).unwrap();
        let id_self = *id;
        *id += 1;
        match *self {
            Node::Leaf => (),
            Node::Two { ref left, ref right, .. } => {
                if let Some(id_child) = left.dot_graph(id, wr) {
                    writeln!(wr, "  node{}:l -> node{}", id_self, id_child).unwrap();
                }

                if let Some(id_child) = right.dot_graph(id, wr) {
                    writeln!(wr, "  node{}:r -> node{}", id_self, id_child).unwrap();
                }
            }
            Node::Three { ref left, ref middle, ref right, .. } => {
                if let Some(id_child) = left.dot_graph(id, wr) {
                    writeln!(wr, "  node{}:l -> node{}", id_self, id_child).unwrap();
                }

                if let Some(id_child) = middle.dot_graph(id, wr) {
                    writeln!(wr, "  node{}:m -> node{}", id_self, id_child).unwrap();
                }

                if let Some(id_child) = right.dot_graph(id, wr) {
                    writeln!(wr, "  node{}:r -> node{}", id_self, id_child).unwrap();
                }
            }
        }
        Some(id_self)
    }

    pub fn dot_label(&self) -> String {
        match *self {
            Node::Leaf => "".to_owned(),
            Node::Two { ref value, .. } => {
                format!("<l> | {} | <r>", value.to_string())
            }
            Node::Three { ref l_value, ref r_value, .. } => {
                format!("<l> | {} | <m> | {} | <r>", l_value.to_string(), r_value.to_string())
            }
        }
    }
}

impl<T: Ord> TwoThreeTree<T> {
    pub fn new() -> TwoThreeTree<T> {
        TwoThreeTree {
            root: Node::leaf_boxed(),
        }
    }

    pub fn insert(&mut self, x: T) {
        let root = std::mem::replace(&mut self.root, Node::leaf_boxed());
        match root.insert(x) {
            InsRes::Consumed(node) => {
                self.root = node;
            }
            InsRes::Pushed(new_value, left, right) => {
                self.root = Box::new(
                    Node::Two {
                        value: new_value,
                        left,
                        right,
                    }
                );
            }
        }
    }

    pub fn count(&self) -> usize {
        self.root.count()
    }

    pub fn contains(&self, x: &T) -> bool {
        let mut cur = self.root.as_ref();
        loop {
            match *cur {
                Node::Leaf => return false,
                Node::Two { ref value, ref left, ref right } => {
                    if x == value {
                        return true;
                    } else if x < value {
                        cur = left;
                    } else {
                        cur = right;
                    }
                }
                Node::Three { ref l_value, ref r_value, ref left, ref middle, ref right } => {
                    if x < l_value {
                        cur = left;
                    } else if x == l_value {
                        return true;
                    } else if l_value < x && x < r_value {
                        cur = middle;
                    } else if x == r_value {
                        return true;
                    } else if x > r_value {
                        cur = right;
                    }
                }
            }
        }
    }

    pub fn height(&self) -> usize {
        self.root.height()
    }
}

impl<T: Ord + ToString> TwoThreeTree<T> {
    pub fn dot_graph(&self) -> String {
        let mut buffer = Vec::with_capacity(1024);
        let wr = &mut buffer;
        writeln!(wr, "digraph g {{").unwrap();
        writeln!(wr, "  node [shape=record, height=.1];").unwrap();

        self.root.dot_graph(&mut 0, wr);
        writeln!(wr, "}}").unwrap();

        unsafe { String::from_utf8_unchecked(buffer) }
    }
}


#[cfg(test)]
mod tests {
    use super::*;

    use rand::seq::SliceRandom;
    use rand::thread_rng;

    #[test]
    fn smoke() {
        let mut tree = TwoThreeTree::new();
        let data = vec![2, 4, 6, 8, 10, 9, 7, 5, 3, 1];
        for i in data {
            tree.insert(i);
        }
        println!("{}", tree.dot_graph());
        println!("\nHeight = {}", tree.height());

        // Adds duplicate data
        for i in vec![1, 2, 2, 3, 3, 3] {
            tree.insert(i);
        }
        assert_eq!(tree.count(), 10);
    }

    #[test]
    fn randomized() {
        for _ in 0..100 {
            const N: usize = 20;
            let mut rng = thread_rng();
            let mut data = (1..=N).collect::<Vec<_>>();
            data.shuffle(&mut rng);

            let mut tree = TwoThreeTree::new();
            for &i in &data {
                tree.insert(i);
            }

            assert_eq!(tree.count(), N);
            let _ = tree.height(); // If it doesn't panic, the tree is balanced.

            for i in &data {
                assert!(tree.contains(i));
            }
            assert!(!tree.contains(&0));
            assert!(!tree.contains(&(N + 1)));
        }
    }
}
