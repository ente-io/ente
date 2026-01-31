use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq, Hash)]
#[serde(rename_all = "snake_case")]
pub struct SyncCursor {
    pub base_since_time: i64,
    pub since_time: i64,
    pub max_time: i64,
    pub since_type: String,
    pub since_id: String,
}

impl Default for SyncCursor {
    fn default() -> Self {
        Self {
            base_since_time: 0,
            since_time: 0,
            max_time: 0,
            since_type: "sessions".to_string(),
            since_id: "00000000-0000-0000-0000-000000000000".to_string(),
        }
    }
}

impl SyncCursor {
    pub fn is_complete_cycle(&self) -> bool {
        self.since_type == "sessions"
            && self.since_time == self.base_since_time
            && self.since_time == self.max_time
    }
}
