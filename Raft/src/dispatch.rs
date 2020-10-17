use std::collections::VecDeque;

use rand::{Rng, thread_rng};

use crate::message::*;

const DEFAULT_QUEUE_SIZE: usize = 8192;

pub struct Dispatcher {
    messages: Vec<VecDeque<Message>>,
    count: usize,
}

impl Dispatcher {
    pub fn new(n_servers: usize) -> Self {
        assert!(n_servers > 0, "No servers?");

        Dispatcher {
            messages: (0..n_servers).map(|_|
                VecDeque::with_capacity(DEFAULT_QUEUE_SIZE)
            ).collect(),
            count: 0,
        }
    }

    pub fn push(&mut self, msg: Message) {
        self.messages[msg.sender_id].push_back(msg);
        self.count += 1;
    }

    // The implementation behaves like TCP instead of UDP.
    pub fn pop(&mut self) -> Option<Message> {
        let i = match self.random_queue() {
            Some(i) => i,
            None => return None,
        };

        self.count -= 1;
        self.messages[i].pop_front()
    }

    pub fn peek(&self) -> Option<&Message> {
        let i = match self.random_queue() {
            Some(i) => i,
            None => return None,
        };
        self.messages[i].front()
    }

    fn random_queue(&self) -> Option<usize> {
        if self.count == 0 {
            return None;
        }

        let mut rng = thread_rng();
        let mut k = rng.gen_range(0, self.count);
        for (i, q) in self.messages.iter().enumerate() {
            if k < q.len() {
                return Some(i);
            }
            k -= q.len();
        }
        unreachable!();
    }
}
