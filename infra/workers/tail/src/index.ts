/**
 * A tail worker that forwards all `console.log` (and siblings) to Loki.
 *
 * https://developers.cloudflare.com/workers/observability/logging/tail-workers/
 */
export default {
    async tail(events: TraceItem[], env: Env) {
        // If the tail worker itself throws an exception (it shouldn't, unless
        // Loki is down), we don't catch it so that it counts as an "error" in
        // the worker stats.
        await handleTail(events, env);
    },
} satisfies ExportedHandler<Env>;

interface Env {
    /** The URL of the Loki instance to push logs to. */
    LOKI_PUSH_URL: string;
    /**
     * The value of the "Basic" authorization.
     *
     * [Note: HTTP basic authorization in worker fetch]
     *
     * Usually a Loki push URL is specified with the credentials inline, say
     * `http://user:pass@loki/path`. However, I cannot get that to work with the
     * `fetch` inside a Cloudflare worker. Instead, the credentials need to be
     * separately provided as the Authorization header of the form:
     *
     *     Authorization: Basic ${btoa(user:pass)}
     *
     * The LOKI_AUTH secret is the "${btoa(user:pass)}" value.
     */
    LOKI_AUTH: string;
}

const handleTail = async (events: TraceItem[], env: Env) => {
    for (const event of events.filter(hasLogOrException))
        await pushLogLine(Date.now(), JSON.stringify(event), env);
};

/** Return true if the {@link event} has at least one log or exception. */
const hasLogOrException = (event: TraceItem) =>
    event.logs.length ?? event.exceptions.length;

/**
 * Send a log entry to (Grafana) Loki
 *
 * For more details about the protocol, see
 * https://grafana.com/docs/loki/latest/reference/loki-http-api/#ingest-logs
 *
 * @param timestampMs Unix epoch (in milliseconds) when the event occurred.
 *
 * @param logLine The message to log.
 *
 * @param env The worker environment; we need it for the Loki URL and
 * credentials.
 */
const pushLogLine = async (timestampMs: number, logLine: string, env: Env) =>
    await fetch(env.LOKI_PUSH_URL, {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
            Authorization: `Basic ${env.LOKI_AUTH}`,
        },
        body: JSON.stringify({
            streams: [
                {
                    stream: { job: "worker" },
                    values: [[`${timestampMs * 1e6}`, logLine]],
                },
            ],
        }),
    });
