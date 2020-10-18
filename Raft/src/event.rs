use lazy_static::lazy_static;
use rand::{prelude::*, distributions::WeightedIndex};

// The parameters in this mod are just set arbitrarily.

// For now network partition is implicitly implemented (by dropping messages).
#[derive(Debug)]
pub enum Event {
    /// Time tick (delta)
    Tick(u64),

    /// Fetches a random message from message queue
    FetchMessage,

    /// Peek the message queue for a random message, but does not dequeue it
    DuplicateMessage,

    /// Drops a random message from message queue
    DropMessage,

    /// Client issues set KV command
    ClientCommand {
        key: String,
        value: String,
    },

    /// Crashes a random server
    ServerCrash,
}

const WEIGHTS: &[f64] = &[1.0, 1.0, 0.1, 0.1, 0.5, 0.1]; // FIXME
lazy_static! {
    static ref DIST: WeightedIndex<f64> = WeightedIndex::new(WEIGHTS).unwrap();
}

impl Event {
    // TODO: Refactoring
    pub fn random<R: Rng>(rng: &mut R) -> Self {
        match DIST.sample(rng) {
            0 => Event::Tick(rng.gen_range(0, 50)),
            1 => Event::FetchMessage,
            2 => Event::DuplicateMessage,
            3 => Event::DropMessage,
            4 => Event::ClientCommand {
                key: format!("{}", rng.gen_range(0, 10)),
                value: format!("{}", rng.gen_range(0, 100)),
            },
            5 => Event::ServerCrash,
            _ => unreachable!(),
        }
    }
}
