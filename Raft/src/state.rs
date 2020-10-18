use std::collections::HashSet;

pub enum State {
    // Reinitialized after election
    Leader {
        next_indices: Vec<usize>,
        match_indices: Vec<Option<usize>>,
    },

    Follower,

    Candidate {
        votes_responded: HashSet<usize>,
        votes_granted: HashSet<usize>,
    },
}

impl Default for State {
    fn default() -> Self {
        State::Follower
    }
}

impl State {
    pub fn default_leader(n: usize, next_index: usize) -> State {
        State::Leader {
            next_indices: vec![next_index; n],
            match_indices: vec![None; n],
        }
    }

    pub fn default_candidate() -> State {
        State::Candidate {
            votes_responded: HashSet::new(),
            votes_granted: HashSet::new(),
        }
    }
}
