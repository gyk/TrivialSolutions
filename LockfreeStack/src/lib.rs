//! Lock-free Stack
//! ===============
//!
//! When implemented in programming languages with GC, [Treiber's stack][stack] does not suffer from
//! [ABA][aba] problem. But in PLs like C++ and Rust, it is much harder to get right.
//!
//! # References
//!
//! - [`lockfree`](https://gitlab.com/bzim/lockfree) crate and the corresponding [blog post][lockfree].
//! - [Someone is wrong on the Internet — the lock-free stack edition][wrong] explains why GCed
//!   languages don't have ABA problem.
//!
//! [stack]: https://en.wikipedia.org/wiki/Treiber_Stack
//! [aba]: https://en.wikipedia.org/wiki/ABA_problem
//! [lockfree]: https://bzim.gitlab.io/blog/posts/incinerator-the-aba-problem-and-concurrent-reclamation.html
//! [wrong]: http://blog.boyet.com/blog/blog/someone-is-wrong-on-the-internet-mdash-the-lock-free-stack-edition

pub mod stack;
mod garbage_queue;

#[cfg(test)]
mod tests {
    use std::sync::Arc;
    use std::thread;

    use stack::Stack;

    #[test]
    fn smoke() {
        let stk = Arc::new(Stack::new());
        let stk_t = Arc::clone(&stk);

        let join = thread::spawn(move || {
            for i in 1000..1100 {
                if i % 4 == 1 {
                    let _ = stk_t.pop();
                } else {
                    stk_t.push(i);
                }
                thread::yield_now();
            }
        });

        for i in 0..100 {
            if i % 4 == 1 {
                let _ = stk.pop();
            } else {
                stk.push(i);
            }
            thread::yield_now();
        }

        join.join().unwrap();

        while let Some(x) = stk.pop() {
            print!("{} ", x);
        }
        println!("");
    }
}
