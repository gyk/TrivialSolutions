use std::ptr;
use std::mem;
use std::fmt::Debug;

#[derive(Debug)]
pub struct Node<T> {
    next: Option<Box<Node<T>>>,
    prev: Rawlink<Node<T>>,
    value: T,
}

impl<T> Node<T> {
    fn new(elem: T) -> Self {
        Node {
            next: None,
            prev: Rawlink::null(),
            value: elem,
        }
    }
}

// Note: using `#[derive(Copy, Clone)]` will not work. See
// https://github.com/rust-lang/rust/issues/26925
#[derive(Debug)]
struct Rawlink<T> {
    ptr: *mut T,
}

impl<T> Copy for Rawlink<T> { }

impl<T> Clone for Rawlink<T> {
    fn clone(&self) -> Self {
        *self
    }
}

#[allow(dead_code)]
impl<T> Rawlink<T> {
    pub fn null() -> Self {
        Rawlink { ptr: ptr::null_mut() }
    }

    pub fn new(link: &mut T) -> Self {
        Rawlink { ptr: link }
    }

    pub fn is_null(&self) -> bool {
        self.ptr.is_null()
    }

    pub fn take(&mut self) -> Self {
        mem::replace(self, Rawlink::null())
    }

    pub fn as_ref(&self) -> Option<&T> {
        unsafe {
            if self.ptr.is_null() {
                None
            } else {
                Some(&*self.ptr)
            }
        }
    }

    pub fn as_mut(&mut self) -> Option<&mut T> {
        unsafe {
            if self.ptr.is_null() {
                None
            } else {
                Some(&mut *self.ptr)
            }
        }
    }
}

// I'd like to implement `Deref` & `DerefMut` traits for Rawlink, but currently Rust doesn't support
// unsafe trait impl (sth like https://internals.rust-lang.org/t/pre-rfc-unsafe-trait-impls/569).

pub struct DoublyLinkedList<T> {
    length: usize,
    head: Option<Box<Node<T>>>,
    tail: Rawlink<Node<T>>,
}

impl<T> DoublyLinkedList<T> {
    pub fn new() -> Self {
        DoublyLinkedList {
            length: 0,
            head: None,
            tail: Rawlink::null(),
        }
    }

    pub fn len(&self) -> usize {
        self.length
    }

    pub fn is_empty(&self) -> bool {
        self.len() == 0
    }

    pub fn push_back(&mut self, elem: T) {
        let mut new_tail = Box::new(Node::new(elem));
        let t = Rawlink::new(new_tail.as_mut());

        if self.is_empty() {
            self.head = Some(new_tail);
        } else {
            new_tail.prev = self.tail;
            self.tail.as_mut().unwrap().next = Some(new_tail);
        }
        
        self.tail = t;
        self.length += 1;
    }

    pub fn push_front(&mut self, elem: T) {
        let mut new_head = Box::new(Node::new(elem));

        match self.head {
            Some(ref mut just_head) => {
                let mut old_head = mem::replace(just_head, new_head);
                old_head.prev = Rawlink::new(just_head.as_mut());
                just_head.next = Some(old_head);
            }
            None => {
                self.tail = Rawlink::new(new_head.as_mut());
                self.head = Some(new_head);
            }
        }

        self.length += 1;
    }

    pub fn pop_back(&mut self) -> Option<Box<Node<T>>> {
        if self.is_empty() {
            return None;
        }

        self.length -= 1;
        let mut tail = self.tail.take();
        match tail.as_mut().unwrap().prev.as_mut() {
            Some(penultimate) => {
                self.tail = Rawlink::new(penultimate);
                penultimate.next.take()
            }
            None => {
                self.tail.take();
                self.head.take()
            }
        }
    }

    pub fn pop_front(&mut self) -> Option<Box<Node<T>>> {
        if self.is_empty() {
            return None;
        }

        self.length -= 1;
        let mut popped = self.head.take();
        self.head = popped.as_mut().unwrap().next.take();
        match self.head {
            Some(ref mut just_head) => just_head.prev = Rawlink::null(),
            None => self.tail = Rawlink::null(),
        }
        popped
    }

    pub fn print(&self) where T: Debug {
        let mut p = &self.head;
        print!("[");
        while let Some(ref node) = *p {
            print!("{:?}", node.value);
            p = &node.next;
            if p.is_some() {
                print!(", ");
            }
        }
        println!("]");
    }
}



fn randomized_test() {
    use std::collections::VecDeque;
    use std::time::{SystemTime, UNIX_EPOCH};

    const N: usize = 50;

    let mut list = DoublyLinkedList::new();
    let mut deque = VecDeque::new();

    let mut seed = SystemTime::now()
        .duration_since(UNIX_EPOCH).unwrap()
        .subsec_nanos() / 1_000_000;

    // LCG random numbers
    let operations = (0..N).map(|_| {
        seed = 1664525_u32.wrapping_mul(seed).wrapping_add(1013904223_u32);
        seed % 100
    }).collect::<Vec<_>>();
    
    for i in 0..N {
        match operations[i] {
            // Better to use `0..40`, but exclusive range pattern syntax is experimental
            0...39 => {
                list.push_back(i);
                deque.push_back(i);
            }
            40...79 => {
                list.push_front(i);
                deque.push_front(i);
            }
            80...89 => {
                list.pop_back();
                deque.pop_back();
            }
            90...99 => {
                list.pop_front();
                deque.pop_front();
            }
            _ => unreachable!(),
        }
        assert_eq!(list.len(), deque.len());
    }

    list.print();
    println!("{:?}", deque);
    while !list.is_empty() {
        assert_eq!((*list.pop_front().unwrap()).value, deque.pop_front().unwrap());
    }
    assert!(deque.is_empty());
}

fn main() {
    let mut list = DoublyLinkedList::new();
    list.push_back(2);
    list.push_back(3);
    list.push_back(5);
    list.push_back(7);
    list.push_front(-1);
    list.push_front(-3);
    list.push_front(-6);
    list.pop_back().unwrap();
    list.push_back(11);
    list.pop_front().unwrap();
    list.pop_front().unwrap();

    list.print();
    list.push_back(13);

    if let Some(p) = list.pop_back() {
        println!("Popped back: {:?}", p.value);
    }

    println!("Length = {}", list.len());

    randomized_test();
}
