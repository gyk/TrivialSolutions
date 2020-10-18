//! A slow, incomplete, single-threaded simulator of the Raft consensus algorithm.
//!
//! # Reference
//!
//! - Ongaro, Diego, and John K. Ousterhout. "In search of an understandable consensus algorithm.
//!   (Extended Version)" USENIX Annual Technical Conference. 2014.
//! - https://github.com/ongardie/raft.tla/blob/master/raft.tla

// NOTE:
//
// - (!) THIS IMPLEMENTATION IS VERY BUGGY AND DOES NOT WORK AT ALL.
// - Only the state transition part is implemented, which means
//     - Just passing around Rust struct/enum for RPCs, with no (de)serialization
//     - No network IO / storage abstraction
// - The implementation is 0-based and uses `None` instead of 0 to indicate missing value.
// - State transitions are expressed as individual functions, so they must be either atomic or
//   idempotent in the real implementation.

// What it lacks from the protocol:
//
// - Prevote
// - Cluster membership changes support
// - Log compaction
// - Accelerated log backtracking

// TODO:
//
// - Harpoon consensus

use std::cell::RefCell;
use std::rc::Rc;
use std::sync::{Arc, atomic::{AtomicBool, Ordering}};

use rand::{thread_rng, Rng};

mod dispatch;
mod event;
mod log_entry;
mod message;
mod server;
mod state;

use dispatch::*;
use event::*;
pub use log_entry::*;
pub use message::*;
pub use server::*;

pub struct Simulator {
    servers: Vec<Server>,
    dispatcher: Rc<RefCell<Dispatcher>>,
}

impl Simulator {
    pub fn new(n_servers: usize) -> Self {
        let dispatcher = Rc::new(RefCell::new(Dispatcher::new(n_servers)));
        let servers = (0..n_servers)
            .map(|id| Server::new(n_servers, id, Rc::clone(&dispatcher)))
            .collect();

        Simulator {
            servers,
            dispatcher,
        }
    }

    pub fn run(&mut self, running: Arc<AtomicBool>) {
        let mut ts: u64 = 0;
        let mut rng = thread_rng();

        while running.load(Ordering::Relaxed) {
            let ev = Event::random(&mut rng);
            println!("Event: {:?}", ev);
            match ev {
                Event::Tick(delta) => {
                    ts += delta;
                    // FIXME: This implies all the servers have synchronized timers, which is
                    // unrealistic.
                    for server in &mut self.servers {
                        server.tick(ts);
                    }
                }
                Event::FetchMessage => {
                    let msg = {
                        let mut dispatcher = self.dispatcher.borrow_mut();
                        dispatcher.pop()
                    };
                    if let Some(msg) = msg {
                        self.servers[msg.receiver_id].handle_message(msg);
                    }
                }
                Event::DuplicateMessage => {
                    let msg = {
                        let dispatcher = self.dispatcher.borrow();
                        dispatcher.peek().cloned()
                    };
                    if let Some(msg) = msg {
                        self.servers[msg.receiver_id].handle_message(msg);
                    }
                }
                Event::DropMessage => {
                    let mut dispatcher = self.dispatcher.borrow_mut();
                    dispatcher.pop();
                }
                Event::ClientCommand { key, value } => {
                    for server in &mut self.servers {
                        if server.is_leader() {
                            server.handle_client_command(key, value);
                            break;
                        }
                    }
                }
                Event::ServerCrash => {
                    let server_id = rng.gen_range(0, self.servers.len());
                    self.servers[server_id].restart();
                }
            }
        }

        println!("\nStopping...");
        for (i, server) in self.servers.iter().enumerate() {
            println!("Server #{}:", i);
            for (k, v) in server.kv_map() {
                println!("\t{} -> {}", k, v);
            }
        }
    }
}

#[cfg(test)]
mod tests {
    #[test]
    fn it_works() {
        assert_eq!(2 + 2, 4);
    }
}
