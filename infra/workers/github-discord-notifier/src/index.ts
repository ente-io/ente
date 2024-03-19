/**
 * Forward notifications from GitHub to Discord.
 *
 * This worker receives webhooks from GitHub, filters out the ones we don't
 * need, and forwards them to a Discord webhook.
 *
 * [Note: GitHub specific Discord Webhooks]
 *
 * By appending `/github` to the end of the webhook URL, we can get Discord to
 * automatically parse the payload sent by GitHub.
 * https://discord.com/developers/docs/resources/webhook#execute-githubcompatible-webhook
 *
 * Note that this doesn't work for all events. And sadly, the events it doesn't
 * work for get silently ignored (Discord responds with a 204).
 * https://github.com/discord/discord-api-docs/issues/6203#issuecomment-1608151265
 */
export default {
    async fetch(request: Request, env: Env) {
        return handleRequest(request, env.DISCORD_WEBHOOK_URL);
    },
} satisfies ExportedHandler<Env>;

interface Env {
    DISCORD_WEBHOOK_URL: string;
}

const handleRequest = async (request: Request, targetURL: string) => {
    const requestBody = await request.text();
    let sender = JSON.parse(requestBody)["sender"]["login"];
    if (sender === "cloudflare-pages[bot]" || sender === "CLAassistant") {
        // Ignore pings from CF bot
        return new Response(null, { status: 200 });
    }

    const response = await fetch(targetURL, {
        method: request.method,
        headers: request.headers,
        body: requestBody,
    });

    const responseBody = await response.text();
    const newResponse = new Response(responseBody, {
        status: response.status,
        statusText: response.statusText,
        headers: response.headers,
    });

    return newResponse;
};
