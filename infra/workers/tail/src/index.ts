/**
 * A tail worker that forwards all `console.log`s to Loki.
 *
 * https://developers.cloudflare.com/workers/observability/logging/tail-workers/
 */
export default {
    async tail(events: TraceItem[], env: Env) {
        // If the tail worker itself throws an exception (it shouldn't, unless
        // Loki is down), we don't catch it so that it counts as an "error" in
        // the worker stats.
        return handleTail(events, env.LOKI_PUSH_URL);
    },
} satisfies ExportedHandler<Env>;

interface Env {
    LOKI_PUSH_URL: string;
}

const handleTail = async (events: TraceItem[], lokiPushURL: string) => {};

/**
 * Send a log entry to (Grafana) Loki
 *
 * For more details about the protocol, see
 * https://grafana.com/docs/loki/latest/reference/loki-http-api/#ingest-logs
 *
 * @param tsNano Unix epoch in nanoseconds when the event occurred.
 *
 * @param logLine The message to log.
 *
 * @param lokiPushURL The URL of the Loki instance to push logs to. The
 * credentials are part of the URL.
 */
const pushLogLine = async (
    tsNano: number,
    logLine: string,
    lokiPushURL: string
) =>
    fetch(lokiPushURL, {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
        },
        body: JSON.stringify({
            streams: [
                {
                    stream: {
                        job: "cf-worker",
                    },
                    values: [[`${tsNano}`, logLine]],
                },
            ],
        }),
    });
