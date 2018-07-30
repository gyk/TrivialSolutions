//! Peterson's Lock

use std::cell::UnsafeCell;
use std::sync::atomic::{AtomicBool, AtomicUsize, Ordering};
use std::thread;

// For the pitfall in implementing Peterson's lock, see
// <https://www.justsoftwaresolutions.co.uk/threading/petersons_lock_with_C++0x_atomics.html>.
//
// Quote from Anthony Williams's comment on Bartosz Milewski's original code:
//
// > You are right that the store does synchronize-with the load *if the load sees the value
// > stored*.
// >
// > However, the problem is that the load *might not see the store* unless there is some *other*
// > cause for synchronization. Even though thread 0 has stored true to `_interested[0]`, thread 1
// > might still read false due to the vagaries of caching and the lack of explicit memory ordering.
// > If thread 1 reads false then it breaks out of the while loop, potentially prematurely.
// >
// > "Synchronizes with" does not affect ordering on a single variable. If operations on one
// > variable synchronize-with each other, that imposes orderings on accesses to *other* variables.
//
// "The vagaries of caching" is the culprit. So the key point is use an intermediary variable to
// make sure the "happens-before" relationship does occur, rather than just the "synchronizes-with"
// one.

pub struct PetersonLock {
    pub interested: [AtomicBool; 2],
    pub victim: AtomicUsize,
}

unsafe impl Sync for PetersonLock {}

impl PetersonLock {
    pub fn new() -> PetersonLock {
        PetersonLock {
            interested: [AtomicBool::new(false), AtomicBool::new(false)],
            victim: AtomicUsize::new(0),
        }
    }

    pub fn lock(&self, tid: usize) -> PetersonLockGuard {
        self.interested[tid].store(true, Ordering::Relaxed);
        self.victim.swap(tid, Ordering::AcqRel);

        while self.interested[1 - tid].load(Ordering::Acquire) &&
            self.victim.load(Ordering::Relaxed) == tid {
            thread::yield_now();
        }

        PetersonLockGuard {
            p_lock: self,
            tid: tid,
        }
    }

    pub fn unlock(&self, tid: usize) {
        self.interested[tid].store(false, Ordering::Release);
    }
}

pub struct PetersonLockGuard<'a> {
    p_lock: &'a PetersonLock,
    tid: usize,
}
// impl<'a> !Send for PetersonLockGuard<'a> {}
impl<'a> Drop for PetersonLockGuard<'a> {
    #[inline]
    fn drop(&mut self) {
        self.p_lock.unlock(self.tid);
    }
}

// This is not so rust-y, but I choose to make it look more like in other languages.
#[derive(Default)]
struct Counter {
    inner: UnsafeCell<usize>,
}
unsafe impl Sync for Counter {}

fn main() {
    use std::sync::Arc;

    const N: usize = 10000;

    let counter = Arc::new(Counter::default());
    let counter1 = Arc::clone(&counter);

    let peterson = Arc::new(PetersonLock::new());
    let peterson1 = Arc::clone(&peterson);

    let join = thread::spawn(move || {
        let tid = 0;
        for _i in 0..N {
            let _lock = peterson.lock(tid);
            let old_cnt = unsafe { *counter.inner.get() };
            let new_cnt = old_cnt + 1;
            unsafe { *counter.inner.get() = new_cnt; }
        }
    });

    let tid = 1;
    for _i in 0..N {
        let _lock = peterson1.lock(tid);
        let old_cnt = unsafe { *counter1.inner.get() };
        let new_cnt = old_cnt + 1;
        unsafe { *counter1.inner.get() = new_cnt; }
    }

    join.join().unwrap();
    let n = unsafe { *counter1.inner.get() };
    println!("Counter = {}", n);
    assert_eq!(n, N * 2);
}
