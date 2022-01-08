export type JobState = 'Scheduled' | 'Running' | 'NotScheduled';

export interface JobConfig {
    intervalSec: number;
    maxItervalSec: number;
    backoffMultiplier: number;
}

export interface JobResult {
    shouldBackoff: boolean;
}

export class SimpleJob<R extends JobResult> {
    private config: JobConfig;
    private runCallback: () => Promise<R>;
    private state: JobState;
    private stopped: boolean;
    private intervalSec: number;
    private nextTimeoutId: ReturnType<typeof setTimeout>;

    constructor(config: JobConfig, runCallback: () => Promise<R>) {
        this.config = config;
        this.runCallback = runCallback;
        this.state = 'NotScheduled';
        this.stopped = true;
        this.intervalSec = this.config.intervalSec;
    }

    public resetInterval() {
        this.intervalSec = this.config.intervalSec;
    }

    public start() {
        this.stopped = false;
        this.resetInterval();
        if (this.state !== 'Running') {
            this.scheduleNext();
        }
    }

    private scheduleNext() {
        if (this.state === 'Scheduled' || this.nextTimeoutId) {
            this.clearScheduled();
        }

        this.nextTimeoutId = setTimeout(
            () => this.run(),
            this.intervalSec * 1000
        );
        this.state = 'Scheduled';
        console.log('Scheduled next job after: ', this.intervalSec);
    }

    async run() {
        this.nextTimeoutId = undefined;
        this.state = 'Running';

        try {
            const jobResult = await this.runCallback();
            if (jobResult.shouldBackoff) {
                this.intervalSec = Math.min(
                    this.config.maxItervalSec,
                    this.intervalSec * this.config.backoffMultiplier
                );
            } else {
                this.resetInterval();
            }
            console.log('Job completed');
        } catch (e) {
            console.error('Error while running Job: ', e);
        } finally {
            this.state = 'NotScheduled';
            !this.stopped && this.scheduleNext();
        }
    }

    public stop() {
        this.stopped = true;
        this.clearScheduled();
    }

    private clearScheduled() {
        clearTimeout(this.nextTimeoutId);
        this.nextTimeoutId = undefined;
        console.log('Cleared next job');
    }
}
