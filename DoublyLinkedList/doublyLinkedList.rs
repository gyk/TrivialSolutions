use std::ptr;
use std::mem;

use std::fmt::Debug;

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

// Note: using `#[derive(Copy, Clone)]` will not work, for unknown reasons it requires 
// `Copy + Clone` trait bound for `<T>`
struct Rawlink<T> {
    ptr: *mut T,
}

impl<T> Copy for Rawlink<T> { }

impl<T> Clone for Rawlink<T> {
    fn clone(&self) -> Rawlink<T> {
        Rawlink {
            ptr: self.ptr,
        }
    }
}

impl<T> Rawlink<T> {
    fn null() -> Self {
        Rawlink { ptr: ptr::null_mut() }
    }

    fn new(link: &mut T) -> Self {
        Rawlink { ptr: link as *mut T }
    }
}

pub struct DoublyLinkedList<T> {
    length: usize,
    head: Option<Box<Node<T>>>,
    tail: Rawlink<Node<T>>,
}

impl<T> DoublyLinkedList<T> {
    fn new() -> Self {
        DoublyLinkedList {
            length: 0,
            head: None,
            tail: Rawlink::null(),
        }
    }

    fn length(&self) -> usize {
        self.length
    }

    fn push_back(&mut self, elem: T) {
        if self.length == 0 {
            self.push_front(elem);
            return;
        }

        let mut new_tail = Box::new(Node::new(elem));
        new_tail.prev = self.tail;
        let t = Rawlink::new(&mut *new_tail);

        let some_tail = Some(new_tail);
        unsafe {
            (*self.tail.ptr).next = some_tail;
        }
        
        self.tail = t;
        self.length += 1;
    }

    fn push_front(&mut self, elem: T) {
        let mut new_head = Box::new(Node::new(elem));

        match self.head {
            Some(ref mut some_head) => {
                mem::swap(some_head, &mut new_head);
                some_head.next = Some(new_head);
            },

            None => {
                self.tail = Rawlink::new(&mut *new_head);
                self.head = Some(new_head);
            }
        }

        self.length += 1;
    }

    // fn pop_back(&mut self) -> Box<T> {
    // }

    // fn pop_front(&mut self) -> Box<T> {
    // }

    fn print(&self) where T: Debug {
        let mut p = &self.head;
        while let Some(ref node) = *p {
            println!("{:?}", node.value);
            p = &node.next;
        }
    }

}

// impl Drop for DoublyLinkedList {
// }

fn main() {
    let mut list = DoublyLinkedList::new();
    list.push_back(2);
    list.push_back(3);
    list.push_back(5);
    list.push_back(7);
    list.push_front(-1);
    list.push_front(-3);
    list.push_front(-6);

    list.print();

    println!("Length = {}", list.length());
}
