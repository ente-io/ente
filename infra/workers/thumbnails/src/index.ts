/** Proxy requests for thumbnails. */

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
    const desktopApp = "ente://app";
    const allowedHostnames = [
        "web.ente.io",
        "photos.ente.io",
        "photos.ente.sh",
        "localhost",
    ];

    if (!origin) return false;
    try {
        const url = new URL(origin);
        return origin == desktopApp || allowedHostnames.includes(url.hostname);
    } catch {
        // origin is likely an invalid URL
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

    const params = new URLSearchParams();
    if (token) params.set("token", token);

    let response = await fetch(
        `https://api.ente.io/files/preview/${fileID}?${params.toString()}`
    );
    response = new Response(response.body, response);
    response.headers.set("Access-Control-Allow-Origin", "*");
    return response;
};
