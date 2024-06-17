/** Proxy requests for files and thumbnails in public albums. */

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
            // "Access-Control-Allow-Headers": "X-Auth-Access-Token, X-Auth-Access-Token-JWT",
            // "Access-Control-Allow-Headers": "X-Auth-Access-Token, X-Auth-Access-Token-JWT, x-client-package",
            "Access-Control-Allow-Headers": "*",
        },
    });
};

const isAllowedOrigin = (origin: string | null) => {
    const allowed = ["albums.ente.io", "albums.ente.sh", "localhost"];

    if (!origin) return false;
    try {
        const url = new URL(origin);
        return allowed.includes(url.hostname);
    } catch {
        // origin is likely an invalid URL
        return false;
    }
};

const areAllowedHeaders = (headers: string | null) => {
    // TODO(MR): Stop sending "x-client-package"
    const allowed = [
        "x-auth-access-token",
        "x-auth-access-token-jwt",
        "x-client-package",
    ];

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

    let accessToken = request.headers.get("X-Auth-Access-Token");
    if (accessToken === undefined) {
        console.warn("Using deprecated accessToken query param");
        accessToken = url.searchParams.get("accessToken");
    }

    if (!accessToken) {
        console.error("No accessToken provided");
        // return new Response(null, { status: 400 });
    }

    let accessTokenJWT = request.headers.get("X-Auth-Access-Token-JWT");
    if (accessTokenJWT === undefined) {
        console.warn("Using deprecated accessTokenJWT query param");
        accessTokenJWT = url.searchParams.get("accessTokenJWT");
    }

    const pathname = url.pathname;

    const params = new URLSearchParams();
    if (accessToken) params.set("accessToken", accessToken);
    if (accessTokenJWT) params.set("accessTokenJWT", accessTokenJWT);

    let response = await fetch(
        `https://api.ente.io/public-collection/files${pathname}${fileID}?${params.toString()}`
    );
    response = new Response(response.body, response);
    response.headers.set("Access-Control-Allow-Origin", "*");
    return response;
};
