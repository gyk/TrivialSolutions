use std::fmt;

use crate::log_entry::*;

// Doubled as heartbeat
#[derive(Debug, Clone)]
pub struct AppendEntriesRequest {
    pub term: u64,
    pub leader_id: usize,

    // Leader sends previous index and term to detect inconsistency.
    // See Raft paper 5.3 Log Matching Property
    pub prev_log_index: Option<usize>,
    pub prev_log_term: u64, // will be 0 if `prev_log_index` is `None`

    pub entries: Vec<LogEntry>,
    pub leader_commit: Option<usize>,
}

#[derive(Debug, Clone)]
pub struct AppendEntriesResponse {
    pub term: u64,
    pub success: bool,
    pub match_index: Option<usize>,
}

#[derive(Debug, Clone)]
pub struct RequestVoteRequest {
    pub term: u64,
    pub candidate_id: usize,

    // The voter denies its vote if its own log is more up-to-date than that of the candidate.
    // See Raft paper 5.4.1 Election restriction.
    pub last_log_index: Option<usize>,
    pub last_log_term: u64,
}

#[derive(Debug, Clone)]
pub struct RequestVoteResponse {
    pub term: u64,
    pub vote_granted: bool,
}

#[derive(Debug, Clone)]
pub enum MessageType {
    AppendEntriesRequest(AppendEntriesRequest),
    AppendEntriesResponse(AppendEntriesResponse),
    RequestVoteRequest(RequestVoteRequest),
    RequestVoteResponse(RequestVoteResponse),
}

#[derive(Debug, Clone)]
pub struct Message {
    pub mtype: MessageType,
    pub sender_id: usize,
    pub receiver_id: usize,
}

impl Message {
    pub fn term(&self) -> u64 {
        match &self.mtype {
            MessageType::AppendEntriesRequest(m) => m.term,
            MessageType::AppendEntriesResponse(m) => m.term,
            MessageType::RequestVoteRequest(m) => m.term,
            MessageType::RequestVoteResponse(m) => m.term,
        }
    }
}

// Displays some concise information.
impl fmt::Display for Message {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        let mtype_str = match &self.mtype {
            MessageType::AppendEntriesRequest(_) => "AppendEntriesRequest",
            MessageType::AppendEntriesResponse(_) => "AppendEntriesResponse",
            MessageType::RequestVoteRequest(_) => "RequestVoteRequest",
            MessageType::RequestVoteResponse(_) => "RequestVoteResponse",
        };

        writeln!(f, "{}: {} -> {}, term = {}",
            mtype_str,
            self.sender_id,
            self.receiver_id,
            self.term())
    }
}
