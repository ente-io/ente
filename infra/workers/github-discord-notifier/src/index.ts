/**
 * Forward notifications from GitHub to Discord.
 *
 * This worker receives webhooks from GitHub, filters out the ones we don't
 * need, and forwards the rest to a Discord webhook.
 */
export default {
    async fetch(request: Request, env: Env) {
        return handleRequest(request, env.DISCORD_WEBHOOK_URL);
    },
} satisfies ExportedHandler<Env>;

interface Env {
    DISCORD_WEBHOOK_URL: string;
}

const handleRequest = async (request: Request, discordWebhookURL: string) => {
    const requestBody = await request.text();
    const requestJSON = JSON.parse(requestBody);
    const sender = requestJSON["sender"]["login"];
    if (sender === "cloudflare-pages[bot]" || sender === "CLAassistant") {
        // Ignore pings from CF bot
        return new Response(null, { status: 200 });
    }

    // [Note: GitHub specific Discord Webhooks]
    //
    // By appending `/github` to the end of the webhook URL, we can get Discord
    // to automatically parse the payload sent by GitHub.
    // https://discord.com/developers/docs/resources/webhook#execute-githubcompatible-webhook
    //
    // Note that this doesn't work for all events. And sadly, the events it
    // doesn't work for get silently ignored (Discord responds with a 204).
    // https://github.com/discord/discord-api-docs/issues/6203#issuecomment-1608151265

    const response = await fetch(`${discordWebhookURL}/github`, {
        method: request.method,
        headers: request.headers,
        body: requestBody,
    });

    if (response.status == 429) {
        // Sometimes Discord starts returning 429 Rate Limited responses when we
        // try to invoke the webhook.
        //
        //    Retry-After: 300
        //    X-Ratelimit-Global: true
        //    X-Ratelimit-Scope: global
        //
        //    {"message": "You are being rate limited.", "retry_after": 0.3, "global": true}
        //
        // This just seems to be a bug on their end, and it goes away on its own
        // after a while. My best guess is that the IP of the Cloudflare Worker
        // somehow gets rate limited because of someone else trying to spam from
        // a worker running on the same IP. But it's a guess. I'm not sure.
        //
        // Ref:
        // https://discord.com/developers/docs/topics/rate-limits#global-rate-limit
        //
        // Interestingly, this only happens for the `/github` specific webhook.
        // The normal webhook still works. So as a workaround, just send a
        // normal text message to the webhook when we get a 429.

        // The JSON sent by GitHub has a varied schema. This is a stop-gap
        // arrangement (we shouldn't be getting 429s forever), so just try to
        // see if we can extract a URL from something we recognize.
        let activityURL: string | undefined;
        if (requestJSON["comment"]) {
            activityURL = requestJSON["comment"]["html_url"];
        }
        if (!activityURL && requestJSON["issue"]) {
            activityURL = requestJSON["issue"]["html_url"];
        }
        if (!activityURL && requestJSON["discussion"]) {
            activityURL = requestJSON["discussion"]["html_url"];
        }

        // Ignore things like issue label changes.
        const action = requestJSON["action"];

        if (activityURL && ["created", "opened"].includes(action)) {
            return fetch(discordWebhookURL, {
                method: request.method,
                headers: request.headers,
                body: JSON.stringify({
                    content: `Activity in ${activityURL}`,
                }),
            });
        }
    }

    return response;
};
