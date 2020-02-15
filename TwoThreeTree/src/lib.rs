//! 2-3 Tree in Rust
//!
//! <https://en.wikipedia.org/wiki/2–3_tree>

use std::cmp::Ordering;
use std::io::Write;

// TODO: Get rid of boilerplate code.
// TODO: Maybe add an enum variant `Leaf` rather than using `Option`?
// TODO: Support key-value
// TODO: Deletion

type Link<T> = Option<Box<Node<T>>>;

// Trait bounds on struct? c.f. https://github.com/rust-lang/rust-clippy/issues/1689
pub struct TwoThreeTree<T: Ord> {
    root: Link<T>,
}

pub enum Node<T: Ord> {
    Two {
        value: T,
        left: Link<T>,
        right: Link<T>,
    },
    Three {
        l_value: T,
        r_value: T,
        left: Link<T>,
        middle: Link<T>,
        right: Link<T>,
    },
}

/// Insertion result
enum InsRes<T: Ord> {
    Consumed(Box<Node<T>>),
    Pushed(T, Link<T>, Link<T>),
}

impl<T: Ord> Node<T> {
    pub fn new2_boxed(value: T) -> Box<Self> {
        Box::new(Node::Two {
            value,
            left: None,
            right: None,
        })
    }

    pub fn new3_boxed(l_value: T, r_value: T) -> Box<Self> {
        Box::new(Node::Three {
            l_value,
            r_value,
            left: None,
            middle: None,
            right: None,
        })
    }
}

// ===== Functions on `Link` =====
fn insert_r<T: Ord>(node: Link<T>, x: T) -> InsRes<T> {
    match node.as_ref().map(AsRef::as_ref) {
        None => {
            return InsRes::Consumed(Node::new2_boxed(x));
        }
        Some(Node::Two { left: None, right: None, .. }) => {
            let node = if let Node::Two { value, .. } = *node.unwrap() {
                match x.cmp(&value) {
                    Ordering::Equal => Node::new2_boxed(value),
                    Ordering::Less => Node::new3_boxed(x, value),
                    Ordering::Greater => Node::new3_boxed(value, x),
                }
            } else {
                unreachable!();
            };
            return InsRes::Consumed(node);
        }
        Some(Node::Two { .. }) => {
            if let Node::Two { value, left, right } = *node.unwrap() {
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
                        match insert_r(left, x) {
                            InsRes::Consumed(left) => {
                                InsRes::Consumed(Box::new(
                                    Node::Two {
                                        value,
                                        left: Some(left),
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
                                        right: right,
                                    }
                                ))
                            }
                        }
                    }
                    Ordering::Greater => {
                        match insert_r(right, x) {
                            InsRes::Consumed(right) => {
                                InsRes::Consumed(Box::new(
                                    Node::Two {
                                        value,
                                        left,
                                        right: Some(right),
                                    }
                                ))
                            }
                            InsRes::Pushed(new_value, new_left, new_right) => {
                                InsRes::Consumed(Box::new(
                                    Node::Three {
                                        l_value: value,
                                        r_value: new_value,
                                        left: left,
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
        Some(Node::Three { left: None, middle: None, right: None, .. }) => {
            if let Node::Three { l_value, r_value, left, middle, right } = *node.unwrap() {
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
                        Some(Node::new2_boxed(l)),
                        Some(Node::new2_boxed(r)),
                    )
                }
            } else {
                unreachable!();
            }
        }
        Some(Node::Three { .. }) => {
            if let Node::Three { l_value, r_value, left, middle, right } = *node.unwrap() {
                if x == l_value || x == r_value {
                    return InsRes::Consumed(Box::new(
                        Node::Three {
                            l_value,
                            r_value,
                            left,
                            middle,
                            right,
                        }
                    ));
                } else if x < l_value {
                    match insert_r(left, x) {
                        InsRes::Consumed(left) => {
                            return InsRes::Consumed(Box::new(
                                Node::Three {
                                    l_value,
                                    r_value,
                                    left: Some(left),
                                    middle,
                                    right,
                                }
                            ));
                        }
                        InsRes::Pushed(new_value, new_left, new_right) => {
                            return InsRes::Pushed(
                                l_value,
                                Some(Box::new(Node::Two {
                                    value: new_value,
                                    left: new_left,
                                    right: new_right,
                                })),
                                Some(Box::new(Node::Two {
                                    value: r_value,
                                    left: middle,
                                    right: right,
                                }))
                            );
                        }
                    }
                } else if x < r_value {
                    match insert_r(middle, x) {
                        InsRes::Consumed(middle) => {
                            return InsRes::Consumed(Box::new(
                                Node::Three {
                                    l_value,
                                    r_value,
                                    left,
                                    middle: Some(middle),
                                    right,
                                }
                            ));
                        }
                        InsRes::Pushed(new_value, new_left, new_right) => {
                            return InsRes::Pushed(
                                new_value,
                                Some(Box::new(Node::Two {
                                    value: l_value,
                                    left: left,
                                    right: new_left,
                                })),
                                Some(Box::new(Node::Two {
                                    value: r_value,
                                    left: new_right,
                                    right: right,
                                }))
                            );
                        }
                    }
                } else {
                    match insert_r(right, x) {
                        InsRes::Consumed(right) => {
                            return InsRes::Consumed(Box::new(
                                Node::Three {
                                    l_value,
                                    r_value,
                                    left,
                                    middle,
                                    right: Some(right),
                                }
                            ));
                        }
                        InsRes::Pushed(new_value, new_left, new_right) => {
                            return InsRes::Pushed(
                                r_value,
                                Some(Box::new(Node::Two {
                                    value: l_value,
                                    left: left,
                                    right: middle,
                                })),
                                Some(Box::new(Node::Two {
                                    value: new_value,
                                    left: new_left,
                                    right: new_right,
                                }))
                            );
                        }
                    }
                }
            } else {
                unreachable!();
            }
        }
    }
}

fn height_r<T: Ord>(node: &Link<T>) -> usize {
    match node.as_ref().map(AsRef::as_ref) {
        None => 0,
        Some(Node::Two { ref left, ref right, .. }) => {
            let l_height = height_r(left);
            let r_height = height_r(right);
            if l_height != r_height {
                panic!("Invalid tree");
            }
            l_height + 1
        }
        Some(Node::Three { ref left, ref middle, ref right, .. }) => {
            let l_height = height_r(left);
            let m_height = height_r(middle);
            let r_height = height_r(right);
            if l_height != m_height || m_height != r_height {
                panic!("Invalid tree");
            }
            l_height + 1
        }
    }
}

fn count_r<T: Ord>(node: &Link<T>) -> usize {
    match node.as_ref().map(AsRef::as_ref) {
        None => 0,
        Some(Node::Two { ref left, ref right, .. }) => {
            let l_count = count_r(left);
            let r_count = count_r(right);
            l_count + r_count + 1
        }
        Some(Node::Three { ref left, ref middle, ref right, .. }) => {
            let l_count = count_r(left);
            let m_count = count_r(middle);
            let r_count = count_r(right);
            l_count + m_count + r_count + 2
        }
    }
}

impl<T: Ord + ToString> Node<T> {
    pub fn dot_graph<W: Write>(&self, id: &mut usize, wr: &mut W) -> usize {
        writeln!(wr, "  node{} [label=\"{}\"]", id, self.dot_label()).unwrap();
        let id_self = *id;
        *id += 1;
        match *self {
            Node::Two { ref left, ref right, .. } => {
                if let Some(left) = left {
                    let id_child = left.dot_graph(id, wr);
                    writeln!(wr, "  node{}:l -> node{}", id_self, id_child).unwrap();
                }
                if let Some(right) = right {
                    let id_child = right.dot_graph(id, wr);
                    writeln!(wr, "  node{}:r -> node{}", id_self, id_child).unwrap();
                }
            }
            Node::Three { ref left, ref middle, ref right, .. } => {
                if let Some(left) = left {
                    let id_child = left.dot_graph(id, wr);
                    writeln!(wr, "  node{}:l -> node{}", id_self, id_child).unwrap();
                }
                if let Some(middle) = middle {
                    let id_child = middle.dot_graph(id, wr);
                    writeln!(wr, "  node{}:m -> node{}", id_self, id_child).unwrap();
                }
                if let Some(right) = right {
                    let id_child = right.dot_graph(id, wr);
                    writeln!(wr, "  node{}:r -> node{}", id_self, id_child).unwrap();
                }
            }
        }
        id_self
    }

    pub fn dot_label(&self) -> String {
        match *self {
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
            root: None,
        }
    }

    pub fn insert(&mut self, x: T) {
        match insert_r(self.root.take(), x) {
            InsRes::Consumed(node) => {
                self.root = Some(node);
            }
            InsRes::Pushed(new_value, left, right) => {
                self.root = Some(Box::new(
                    Node::Two {
                        value: new_value,
                        left,
                        right,
                    }
                ));
            }
        }
    }

    pub fn count(&self) -> usize {
        count_r(&self.root)
    }

    pub fn contains(&self, x: &T) -> bool {
        let mut cur = self.root.as_ref().map(AsRef::as_ref);
        while let Some(curr) = cur {
            match *curr {
                Node::Two { ref value, ref left, ref right } => {
                    if x == value {
                        return true;
                    } else if x < value {
                        cur = left.as_ref().map(AsRef::as_ref);
                    } else {
                        cur = right.as_ref().map(AsRef::as_ref);
                    }
                }
                Node::Three { ref l_value, ref r_value, ref left, ref middle, ref right } => {
                    if x < l_value {
                        cur = left.as_ref().map(AsRef::as_ref);
                    } else if x == l_value {
                        return true;
                    } else if l_value < x && x < r_value {
                        cur = middle.as_ref().map(AsRef::as_ref);
                    } else if x == r_value {
                        return true;
                    } else if x > r_value {
                        cur = right.as_ref().map(AsRef::as_ref);
                    }
                }
            }
        }
        false
    }

    pub fn height(&self) -> usize {
        height_r(&self.root)
    }
}

impl<T: Ord + ToString> TwoThreeTree<T> {
    pub fn dot_graph(&self) -> String {
        let mut buffer = Vec::with_capacity(1024);
        let wr = &mut buffer;
        writeln!(wr, "digraph g {{").unwrap();
        writeln!(wr, "  node [shape=record, height=.1];").unwrap();

        if let Some(ref node) = self.root {
            node.dot_graph(&mut 0, wr);
        }

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
