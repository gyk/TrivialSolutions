use std::cell::RefCell;
use std::cmp;
use std::collections::HashMap;
use std::rc::Rc;

use crate::dispatch::*;
use crate::log_entry::*;
use crate::message::*;
use crate::state::State;

// broadcastTime ≪ electionTimeout ≪ MTBF
const HEARTBEAT_INTERVAL_MS: u64 = 50;
const ELECTION_TIMEOUT_MS: u64 = 500; // FIXME: Randomize

// IMPORTANT: log index is 1-based, as stated in the paper.

pub struct Server {
    // Persistent state on all servers (updated on stable storage before responding to RPCs)
    // ================
    current_term: u64, // FIXME: Uses Option?
    voted_for: Option<usize>,
    logs: Vec<LogEntry>, // will use deque for compaction

    // Volatile state on all servers
    // ================
    commit_index: Option<usize>,
    last_applied: Option<usize>,

    // The role and associated data
    state: State,

    // Not in Raft paper fig. 2, but necessary.
    // ================
    last_broadcast_time: u64,
    last_election_time: u64,
    id: usize,
    n_servers: usize,

    // The dispatcher
    dispatcher: Rc<RefCell<Dispatcher>>,

    // The state machine
    kv: HashMap<String, String>,
}

impl Server {
    pub fn new(n_servers: usize, id: usize, dispatcher: Rc<RefCell<Dispatcher>>) -> Server {
        Server {
            current_term: 0,
            voted_for: None,
            logs: Vec::new(),

            commit_index: None,
            last_applied: None,

            state: State::default(),

            last_broadcast_time: 0, // FIXME
            last_election_time: 0, // FIXME
            id,
            n_servers,

            dispatcher,

            kv: HashMap::new(),
        }
    }

    pub fn restart(&mut self) {
        let _ = std::mem::replace(self,
            Server::new(self.n_servers, self.id, Rc::clone(&self.dispatcher)));
    }

    pub fn tick(&mut self, timestamp: u64) {
        match self.state {
            State::Leader { .. } => {
                if timestamp.saturating_sub(self.last_broadcast_time) > HEARTBEAT_INTERVAL_MS {
                    self.send_append_entries();
                    self.last_broadcast_time = timestamp;
                }
            }
            State::Candidate { .. } => {
                if timestamp.saturating_sub(self.last_election_time) > ELECTION_TIMEOUT_MS {
                    self.start_new_election(timestamp);
                }
            }
            State::Follower => {
                if timestamp.saturating_sub(self.last_election_time) > ELECTION_TIMEOUT_MS {
                    // Transits to Candidate, votes for self
                    self.state = State::default_candidate();
                    self.start_new_election(timestamp);
                }
            }
        }
    }

    pub fn handle_message(&mut self, msg: Message) {
        assert_eq!(msg.receiver_id, self.id);

        // Rules for Servers - All Servers
        self.apply_state();
        if msg.term() > self.current_term { // For both RPC request and response
            self.current_term = msg.term();
            self.state = State::Follower;
        }

        let res_msg = match msg.mtype {
            MessageType::AppendEntriesRequest(m) => Some(
                MessageType::AppendEntriesResponse(self.on_append_entries_request(m, msg.sender_id))
            ),

            MessageType::AppendEntriesResponse(m) => {
                self.on_append_entries_response(m, msg.sender_id);
                None
            }

            MessageType::RequestVoteRequest(m) => Some(
                MessageType::RequestVoteResponse(self.on_request_vote_request(m, msg.sender_id))
            ),

            MessageType::RequestVoteResponse(m) if self.is_candidate() => {
                self.on_request_vote_response(m, msg.sender_id);
                None
            }

            _ => None,
        };

        if let Some(m) = res_msg {
            self.dispatcher.borrow_mut().push(Message {
                mtype: m,
                sender_id: self.id,
                receiver_id: msg.sender_id,
            });
        }
    }

    /// Invoked by leader to replicate log entries; also used as heartbeat.
    fn send_append_entries(&mut self) {
        if let State::Leader { next_indices, .. } = &self.state {
            for i in 0..self.n_servers {
                if i == self.id {
                    continue;
                }

                let next_index = next_indices[i];
                let prev_log_index = next_index.checked_sub(1);
                let prev_log_term = prev_log_index
                    .map(|prev_log_index| self.logs[prev_log_index].term)
                    .unwrap_or(0);
                let entries: Vec<LogEntry> = self.logs[next_index..].to_vec();

                self.dispatcher.borrow_mut().push(Message {
                    mtype: MessageType::AppendEntriesRequest(
                        AppendEntriesRequest {
                            term: self.current_term,
                            leader_id: self.id,
                            prev_log_index,
                            prev_log_term,
                            entries,
                            leader_commit: self.commit_index,
                        }
                    ),
                    sender_id: self.id,
                    receiver_id: i,
                });
            }
        } else {
            unreachable!("Non-leader tries to invoke AppendEntriesRequest");
        }
    }

    fn on_append_entries_request(&mut self, m: AppendEntriesRequest, _leader_id: usize)
        -> AppendEntriesResponse
    {
        // Fig. 2 - AppendEntries - Recv impl - 1
        if m.term < self.current_term {
            return AppendEntriesResponse {
                term: self.current_term,
                success: false,
                match_index: None,
            };
        }

        // If AppendEntries RPC received from the new leader, converts to follower.
        if self.is_candidate() {
            self.state = State::Follower;
        }

        // Fig. 2 - AppendEntries - Recv impl - 2, 3
        let conflict = match m.prev_log_index {
            None => false,
            Some(prev_log_index) => {
                match self.logs.get(prev_log_index) {
                    Some(prev_log) => {
                        if prev_log.term != m.prev_log_term {
                            self.logs.truncate(prev_log_index); // 0-based
                            true
                        } else {
                            false
                        }
                    }
                    None => true,
                }
            }
        };
        if conflict {
            return AppendEntriesResponse {
                term: self.current_term,
                success: false,
                match_index: None,
            };
        }

        self.logs.extend_from_slice(&m.entries);
        let last_log_index = self.last_log_index();

        // Fig. 2 - AppendEntries - Recv impl - 5
        if m.leader_commit > self.commit_index {
            self.commit_index = cmp::min(m.leader_commit, last_log_index);
        }

        AppendEntriesResponse {
            term: self.current_term,
            success: true,
            match_index: last_log_index,
        }
    }

    fn on_append_entries_response(&mut self, m: AppendEntriesResponse, server_id: usize) {
        if let State::Leader { ref mut next_indices, ref mut match_indices } = self.state {
            if m.success {
                next_indices[server_id] = m.match_index.map(|x| x + 1).unwrap_or(0);
                match_indices[server_id] = m.match_index;
            } else {
                // failed
                next_indices[server_id] -= 1;
                // FIXME: What about `match_indices`?
            }

            self.advance_commit_index();
        }
    }

    fn advance_commit_index(&mut self) {
        if let State::Leader { ref mut next_indices, .. } = self.state {
            let mut next_indices = next_indices.clone();
            next_indices.sort(); // No partial_sort??
            let new_commit_index = next_indices.get(self.logs.len() - self.quoram()).copied();
            self.commit_index = cmp::max(self.commit_index, new_commit_index);
        } else {
            panic!("Non-leader tries to advance the commit index");
        }
    }

    fn on_request_vote_request(&mut self, m: RequestVoteRequest, candidate_id: usize)
        -> RequestVoteResponse
    {
        // Fig. 2 - RequestVote - Recv impl

        // Checks if the candidate's log is at least as up-to-date
        let log_ok = m.last_log_term > self.last_log_term() || (
            m.last_log_term == self.last_log_term() &&
            m.last_log_index >= self.last_log_index()
        );

        let granted =
            self.current_term <= m.term &&
            log_ok &&
            self.voted_for.map(|vid| vid == candidate_id).unwrap_or(true);

        RequestVoteResponse {
            term: self.current_term,
            vote_granted: granted,
        }
    }

    fn on_request_vote_response(&mut self, m: RequestVoteResponse, sender_id: usize) {
        if let State::Candidate {
            ref mut votes_responded,
            ref mut votes_granted,
        } = self.state {
            votes_responded.insert(sender_id);
            if m.vote_granted {
                votes_granted.insert(sender_id);
                let n_votes_granted = votes_granted.len();
                // If votes received from majority of servers, becomes leader
                if n_votes_granted >= self.quoram() {
                    self.state = State::default_leader(self.n_servers, self.logs.len());
                    self.send_append_entries();
                }
            }
        }
    }

    pub fn handle_client_command(&mut self, key: String, value: String) {
        if let State::Leader { .. } = self.state {
            self.logs.push(LogEntry {
                term: self.current_term,
                key,
                value,
            });
        }
        // FIXME: Respond after entry applied to state machine.
    }

    pub(crate) fn kv_map(&self) -> &HashMap<String, String> {
        &self.kv
    }

    // ===== Helpers =====

    pub fn last_log_term(&self) -> u64 {
        self.logs.last().map(|l| l.term).unwrap_or(0)
    }

    pub fn quoram(&self) -> usize {
        self.n_servers / 2 + 1
    }

    pub fn is_leader(&self) -> bool {
        match self.state {
            State::Leader { .. } => true,
            _ => false,
        }
    }

    pub fn is_candidate(&self) -> bool {
        match self.state {
            State::Candidate { .. } => true,
            _ => false,
        }
    }

    // Start new election and sends "RequestVoteRequest"s
    fn start_new_election(&mut self, timestamp: u64) {
        if let State::Candidate { ref mut votes_responded, ref mut votes_granted } = self.state {
            votes_responded.clear();
            votes_responded.insert(self.id);
            votes_granted.clear();
            votes_granted.insert(self.id);
        } else {
            panic!("Non-candidate tries to start a new election");
        }

        self.voted_for = Some(self.id);
        self.last_election_time = timestamp; // resets election timer
        self.current_term += 1; // increments currentTerm

        // Sends RequestVote RPCs to all the other servers
        let last_log_index = self.last_log_index();
        let last_log_term = self.last_log_term();
        for i in 0..self.n_servers {
            if i != self.id {
                let rv = Message {
                    mtype: MessageType::RequestVoteRequest(RequestVoteRequest {
                        term: self.current_term,
                        candidate_id: self.id,
                        last_log_index,
                        last_log_term,
                    }),
                    sender_id: self.id,
                    receiver_id: i,
                };
                self.dispatcher.borrow_mut().push(rv);
            }
        }
    }

    fn last_log_index(&self) -> Option<usize> {
        self.logs.len().checked_sub(1)
    }

    // Applies already commited logs to the state machine.
    fn apply_state(&mut self) {
        if let Some(commit_index) = self.commit_index {
            let next_to_apply = self.last_applied.map(|i| i + 1).unwrap_or(0);
            for i in next_to_apply ..= commit_index {
                let log = &self.logs[i];
                self.kv.insert(log.key.clone(), log.value.clone());
                self.last_applied = Some(i);
            }
        }
    }
}
