use std::cell::UnsafeCell;
use std::collections::VecDeque;
use std::sync::atomic::{AtomicUsize, Ordering};

pub struct Pause;
impl Pause {
    pub fn new() -> Self {
        PAUSE_COUNT.fetch_add(1, Ordering::Relaxed);
        Pause
    }
}
impl Drop for Pause {
    fn drop(&mut self) {
        PAUSE_COUNT.fetch_sub(1, Ordering::Relaxed);
    }
}

static PAUSE_COUNT: AtomicUsize = AtomicUsize::new(0);

pub struct Garbage {
    pub pointer: *mut u8, // `void *` in C
    pub dropper: unsafe fn(*mut u8), // `fn` pointer, not `Fn` trait object
}

pub struct GarbageQueue {
    queue: UnsafeCell<VecDeque<Garbage>>,
}
impl GarbageQueue {
    fn new() -> Self {
        Self {
            queue: UnsafeCell::new(VecDeque::with_capacity(16)),
        }
    }

    fn add(&self, garbage: Garbage) {
        let queue = unsafe { &mut *self.queue.get() };
        queue.push_back(garbage);
        if PAUSE_COUNT.load(Ordering::Acquire) == 0 {
            self.delete();
        }
    }

    fn delete(&self) {
        let queue = unsafe { &mut *self.queue.get() };
        while let Some(garbage) = queue.pop_front() {
            unsafe {
                (garbage.dropper)(garbage.pointer);
            }
        }
    }
}
impl Drop for GarbageQueue {
    fn drop(&mut self) {
        while PAUSE_COUNT.load(Ordering::Acquire) != 0 {}
        self.delete();
    }
}

pub fn add_garbage(garbage: Garbage) {
    GARBAGE_QUEUE.with(|queue| {
        queue.add(garbage);
    });
}

thread_local! {
    pub static GARBAGE_QUEUE: GarbageQueue = GarbageQueue::new();
}
