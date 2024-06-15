/** Proxy file and thumbnail requests for the cast web app */

export default {
    async fetch(request: Request) {
        switch (request.method) {
            case "OPTIONS":
                return handleOPTIONS(request);
            case "GET":
                return handleGET(request);
            default:
                console.log(`Unsupported HTTP method ${request.method}`);
                return new Response(null, { status: 405 });
        }
    },
} satisfies ExportedHandler;

const handleOPTIONS = (request: Request) => {
    const origin = request.headers.get("Origin");
    if (!isAllowedOrigin(origin)) console.warn("Unknown origin", origin);
    return new Response("", {
        headers: {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, OPTIONS",
            "Access-Control-Max-Age": "86400",
            "Access-Control-Allow-Headers": "X-Cast-Access-Token",
        },
    });
};

const isAllowedOrigin = (origin: string | null) => {
    if (!origin) return false;
    try {
        const url = new URL(origin);
        return ["cast.ente.io", "cast.ente.sh", "localhost"].includes(
            url.hostname
        );
    } catch {
        // origin is likely an invalid URL
        return false;
    }
};

const handleGET = async (request: Request) => {
    const url = new URL(request.url);
    const castToken =
        request.headers.get("X-Cast-Access-Token") ??
        url.searchParams.get("castToken");
    if (!castToken) {
        console.error("No cast token provided");
        return new Response(null, { status: 400 });
    }

    const fileID = url.searchParams.get("fileID");
    const pathname = url.pathname;

    const params = new URLSearchParams({ castToken });
    let response = await fetch(
        `https://api.ente.io/cast/files${pathname}${fileID}?${params.toString()}`
    );

    response = new Response(response.body, response);
    response.headers.set("Access-Control-Allow-Origin", "*");
    return response;
};
