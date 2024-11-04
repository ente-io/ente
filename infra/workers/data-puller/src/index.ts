/**
 * Proxy requests for downloading files from object storage.
 *
 * Used by museum when replicating.
 */

export default {
    async fetch(request: Request) {
        switch (request.method) {
            case "GET":
                return handleGET(request);
            default:
                console.log(`Unsupported HTTP method ${request.method}`);
                return new Response(null, { status: 405 });
        }
    },
} satisfies ExportedHandler;

const handleGET = async (request: Request) => {
    const url = new URL(request.url);

    // Random bots keep trying to pentest causing noise in the logs. If the
    // request doesn't have a src, we can just safely ignore it.
    const src = url.searchParams.get("src");
    if (!src) return new Response(null, { status: 400 });

    const source = atob(src);

    return fetch(source);
};
