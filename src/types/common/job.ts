import { Config } from './config';

export type JobState = 'Scheduled' | 'Running' | 'NotScheduled';

export interface JobConfig extends Config {
    intervalSec: number;
    maxItervalSec: number;
    backoffMultiplier: number;
}

export interface JobResult {
    shouldBackoff: boolean;
}
