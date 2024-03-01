export type JobState = "Scheduled" | "Running" | "NotScheduled";

export interface JobConfig {
    intervalSec: number;
    maxItervalSec: number;
    backoffMultiplier: number;
}

export interface JobResult {
    shouldBackoff: boolean;
}
