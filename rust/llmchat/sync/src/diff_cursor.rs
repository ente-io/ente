use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq, Hash)]
#[serde(rename_all = "camelCase")]
pub struct SyncCursor {
    #[serde(alias = "base_since_time")]
    pub base_since_time: i64,
    #[serde(alias = "since_time")]
    pub since_time: i64,
    #[serde(alias = "max_time")]
    pub max_time: i64,
    #[serde(alias = "since_type")]
    pub since_type: String,
    #[serde(alias = "since_id")]
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
