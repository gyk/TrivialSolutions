use std::sync::{Arc, atomic::{AtomicBool, Ordering}};

use raft::Simulator;

fn main() {
    let mut simulator = Simulator::new(5);

    let running = Arc::new(AtomicBool::new(true));
    // This seems wrong, but it works...
    ctrlc::set_handler({
        let running = Arc::clone(&running);
        move || {
            running.store(false, Ordering::Relaxed);
        }
    }).expect("Error setting Ctrl-C handler");

    simulator.run(running);
}
