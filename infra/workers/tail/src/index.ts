/**
 * A tail worker that forwards all `console.log` (and siblings) to Loki.
 *
 * https://developers.cloudflare.com/workers/observability/logging/tail-workers/
 */
export default {
    async tail(events: TraceItem[], env: Env, ctx: ExecutionContext) {
        console.log("Length of LOKI_PUSH_URL", env.LOKI_PUSH_URL.length);

        // If the tail worker itself throws an exception (it shouldn't, unless
        // Loki is down), we don't catch it so that it counts as an "error" in
        // the worker stats.
        ctx.waitUntil(handleTail(events, env.LOKI_PUSH_URL, env.LOKI_AUTH));
    },
} satisfies ExportedHandler<Env>;

interface Env {
    LOKI_PUSH_URL: string;
    LOKI_AUTH: string;
}

const handleTail = async (events: TraceItem[], lokiPushURL: string, lokiAuth: string) =>
    await pushLogLine(Date.now(), JSON.stringify(events), lokiPushURL, lokiAuth);

// const handleTail1 = async (events: TraceItem[], lokiPushURL: string) => {
//     for (const event of events.filter(hasLogOrException)) {
//         await pushLogLine(Date.now(), JSON.stringify(event), lokiPushURL);
//     }
// };

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
 * @param lokiPushURL The URL of the Loki instance to push logs to. The
 * credentials are part of the URL.
 */
const pushLogLine = async (
    timestampMs: number,
    logLine: string,
    lokiPushURL: string,
    lokiAuth: string,
) => {
    console.log(
        "Pushing",
        JSON.stringify({
            streams: [
                {
                    stream: { job: "worker" },
                    values: [[`${timestampMs * 1e6}`, logLine]],
                },
            ],
        })
    );
    try {
        const res = await fetch(lokiPushURL, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "Authorization": `Basic ${lokiAuth}`,
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
        console.log(res.status, await res.text()); //JSON.stringify(res));
        return res;
    } catch (e) {
        console.log("Failed", e);
    }
};
