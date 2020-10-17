
#[derive(Debug, Clone)]
pub struct LogEntry {
    pub term: u64,

    // The command. For simplicity, just use String for now.
    pub key: String,
    pub value: String,
}
