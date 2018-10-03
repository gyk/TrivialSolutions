//! Treiber's stack
use std::mem;
use std::ptr;
use std::sync::atomic::AtomicPtr;
use std::sync::atomic::Ordering;

use garbage_queue::{self, Garbage, Pause};

#[derive(Debug)]
pub struct Stack<T> {
    top: AtomicPtr<Node<T>>,
}

impl<T> Stack<T> {
    pub fn new() -> Self {
        Stack {
            top: AtomicPtr::new(ptr::null_mut()),
        }
    }

    pub fn push(&self, value: T) {
        // (!) Do NOT allocate new `Node` on the stack.
        let new_node: *mut Node<T> = Box::into_raw(Box::new(Node::new(value)));
        loop {
            let top: *mut Node<T> = self.top.load(Ordering::Acquire);
            unsafe { (*new_node).next = top; }

            let curr_top = self.top.compare_and_swap(top, new_node, Ordering::Release);
            if curr_top == top {
                break;
            }
        }
    }

    pub fn pop(&self) -> Option<T> {
        loop {
            let ret = {
                let _pause = Pause::new();

                let top: *mut Node<T> = self.top.load(Ordering::Acquire);
                if top.is_null() {
                    return None;
                }

                // This dereference is safe because of the use of hazard pointer.
                let next: *mut Node<T> = unsafe { (*top).next };
                let curr_top = self.top.compare_and_swap(top, next, Ordering::Release);
                if curr_top == top {
                    // Pushes old top pointer to garbage queue.
                    Some(top)
                } else {
                    None
                }
            };

            if let Some(top) = ret {
                let value: T = unsafe {
                    let top_node = &mut *top;
                    mem::replace(&mut top_node.value, mem::uninitialized())
                };
                let garbage = Garbage {
                    pointer: top as *mut u8,
                    dropper: Node::<T>::dropper,
                };
                garbage_queue::add_garbage(garbage);
                return Some(value);
            }
        }
    }
}

#[derive(Debug)]
struct Node<T> {
    value: T,
    next: *mut Node<T>,
}

impl<T> Node<T> {
    pub fn new(value: T) -> Self {
        Node {
            value,
            next: ptr::null_mut(),
        }
    }

    pub unsafe fn dropper(p: *mut u8) {
        let _node = Box::from_raw(p as *mut Self);
    }
}
