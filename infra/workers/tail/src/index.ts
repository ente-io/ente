/**
 * A tail worker that forwards all `console.log`s to Loki.
 *
 * https://developers.cloudflare.com/workers/observability/logging/tail-workers/
 */
export default {
    async tail(events: TailItems[], env: Env) {
        // If the tail worker itself throws an exception (it shouldn't, unless
        // Loki is down), we don't catch it so that it counts as an "error" in
        // the worker stats.
        return handleTail(events, env.LOKI_URL);
    },
} satisfies ExportedHander<Env>;

interface Env {
    LOKI_URL: string;
}

const handleTail = (events: TailItems[], lokiURL: string) => {};
