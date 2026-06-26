use serde::{Deserialize, Serialize};

pub type JobId = i64;

pub trait EventSink {
    fn add(&mut self, event: GenerateEvent);
}

impl<F> EventSink for F
where
    F: FnMut(GenerateEvent),
{
    fn add(&mut self, event: GenerateEvent) {
        (self)(event);
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GenerateSummary {
    pub job_id: JobId,
    pub prompt_tokens: Option<i32>,
    pub generated_tokens: Option<i32>,
    pub total_time_ms: Option<i64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum GenerateEvent {
    Text {
        job_id: JobId,
        text: String,
        token_id: Option<i32>,
    },
    Done {
        summary: GenerateSummary,
    },
    Error {
        job_id: JobId,
        message: String,
    },
}
