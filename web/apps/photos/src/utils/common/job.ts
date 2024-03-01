import { addLogLine } from "@ente/shared/logging";
import { JobConfig, JobResult, JobState } from "types/common/job";

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
        this.state = "NotScheduled";
        this.stopped = true;
        this.intervalSec = this.config.intervalSec;
    }

    public resetInterval() {
        this.intervalSec = this.config.intervalSec;
    }

    public start() {
        this.stopped = false;
        this.resetInterval();
        if (this.state !== "Running") {
            this.scheduleNext();
        } else {
            addLogLine("Job already running, not scheduling");
        }
    }

    private scheduleNext() {
        if (this.state === "Scheduled" || this.nextTimeoutId) {
            this.clearScheduled();
        }

        this.nextTimeoutId = setTimeout(
            () => this.run(),
            this.intervalSec * 1000,
        );
        this.state = "Scheduled";
        addLogLine("Scheduled next job after: ", this.intervalSec);
    }

    async run() {
        this.nextTimeoutId = undefined;
        this.state = "Running";

        try {
            const jobResult = await this.runCallback();
            if (jobResult.shouldBackoff) {
                this.intervalSec = Math.min(
                    this.config.maxItervalSec,
                    this.intervalSec * this.config.backoffMultiplier,
                );
            } else {
                this.resetInterval();
            }
            addLogLine("Job completed");
        } catch (e) {
            console.error("Error while running Job: ", e);
        } finally {
            this.state = "NotScheduled";
            !this.stopped && this.scheduleNext();
        }
    }

    // currently client is responsible to terminate running job
    public stop() {
        this.stopped = true;
        this.clearScheduled();
    }

    private clearScheduled() {
        clearTimeout(this.nextTimeoutId);
        this.nextTimeoutId = undefined;
        this.state = "NotScheduled";
        addLogLine("Cleared next job");
    }
}
