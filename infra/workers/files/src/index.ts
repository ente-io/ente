/** Proxy requests for files. */

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
    const headers = request.headers.get("Access-Control-Request-Headers");
    if (!areAllowedHeaders(headers))
        console.warn("Unknown header in list", headers);
    return new Response("", {
        headers: {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, OPTIONS",
            "Access-Control-Max-Age": "86400",
            // "Access-Control-Allow-Headers": "X-Auth-Token, X-Client-Package",
            "Access-Control-Allow-Headers": "*",
        },
    });
};

const isAllowedOrigin = (origin: string | null) => {
    if (!origin) return false;
    try {
        const url = new URL(origin);
        const hostname = url.hostname;
        return (
            origin == "ente://app" /* desktop app */ ||
            hostname.endsWith("ente.io") ||
            hostname.endsWith("ente.sh") ||
            hostname == "localhost"
        );
    } catch {
        // `origin` is likely an invalid URL.
        return false;
    }
};

const areAllowedHeaders = (headers: string | null) => {
    const allowed = ["x-auth-token", "x-client-package"];

    if (!headers) return true;
    for (const header of headers.split(",")) {
        if (!allowed.includes(header.trim().toLowerCase())) return false;
    }
    return true;
};

const handleGET = async (request: Request) => {
    const url = new URL(request.url);

    // Random bots keep trying to pentest causing noise in the logs. If the
    // request doesn't have a fileID, we can just safely ignore it thereafter.
    const fileID = url.searchParams.get("fileID");
    if (!fileID) return new Response(null, { status: 400 });

    let token = request.headers.get("X-Auth-Token");
    if (!token) {
        console.warn("Using deprecated token query param");
        token = url.searchParams.get("token");
    }

    if (!token) {
        console.error("No token provided");
        // return new Response(null, { status: 400 });
    }

    // We forward the auth token as a query parameter to museum. This is so that
    // it does not get preserved when museum does a redirect to the presigned S3
    // URL that serves the actual thumbnail.
    //
    // See: [Note: Passing credentials for self-hosted file fetches]
    const params = new URLSearchParams();
    if (token) params.set("token", token);

    let response = await fetch(
        `https://api.ente.io/files/download/${fileID}?${params.toString()}`,
        {
            headers: {
                "User-Agent": request.headers.get("User-Agent") ?? "",
            },
        }
    );

    if (!response.ok) console.log("Upstream error", response.status);

    response = new Response(response.body, response);
    response.headers.set("Access-Control-Allow-Origin", "*");
    return response;
};
