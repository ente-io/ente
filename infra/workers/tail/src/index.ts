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
        return handleTail(events, env.LOKI_PUSH_URL);
    },
} satisfies ExportedHandler<Env>;

interface Env {
    LOKI_PUSH_URL: string;
}

const handleTail = async (events: TraceItem[], lokiPushURL: string) => {
    for (const event of events) {
        for (const log of event.logs) {
            pushLogLine(log.timestamp, logLineForLog(log), lokiPushURL);
        }
        for (const e of event.exceptions) {
            pushLogLine(e.timestamp, logLineForException(e), lokiPushURL);
        }
    }
};

const logLineForLog = ({ level, message }: TraceLog) =>
    // https://developers.cloudflare.com/workers/runtime-apis/handlers/tail/#taillog
    //
    // - level: A string indicating the console function that was called. One
    //   of: "debug", "info", "log", "warn", "error".
    //
    // - message: The array of parameters passed to the console function.
    `[${level}] ${(Array.isArray(message) ? message : [message]).join(" ")}`;

const logLineForException = ({ name, message }: TraceException) =>
    // https://developers.cloudflare.com/workers/runtime-apis/handlers/tail/#tailexception
    //
    // - name: The error type (e.g. "Error", "TypeError")
    //
    // - message: The error description.
    `${name}: ${message}`;

/**
 * Send a log entry to (Grafana) Loki
 *
 * For more details about the protocol, see
 * https://grafana.com/docs/loki/latest/reference/loki-http-api/#ingest-logs
 *
 * @param tsNano Unix epoch (in milliseconds) when the event occurred.
 *
 * @param logLine The message to log.
 *
 * @param lokiPushURL The URL of the Loki instance to push logs to. The
 * credentials are part of the URL.
 */
const pushLogLine = async (
    timestampMs: number,
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
                    stream: { job: "cf-worker" },
                    values: [[`${timestampMs * 1e6}`, logLine]],
                },
            ],
        }),
    });
