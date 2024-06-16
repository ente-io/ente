/**
 * Proxy file uploads.
 *
 * See: https://ente.io/blog/tech/making-uploads-faster/
 */

export default {
    async fetch(request: Request) {
        switch (request.method) {
            case "OPTIONS":
                return handleOPTIONS(request);
            // case "GET":
            //     return handleGET(request);
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
            "Access-Control-Allow-Methods": "POST, PUT, OPTIONS",
            "Access-Control-Max-Age": "86400",
            // "Access-Control-Allow-Headers": "UPLOAD-URL",
            "Access-Control-Allow-Headers": "*",
            "Access-Control-Expose-Headers": "X-Request-ID, CF-Ray",
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
    const allowed = ["UPLOAD-URL"];

    if (!headers) return true;
    for (const header of headers.split(",")) {
        if (!allowed.includes(header.trim().toLowerCase())) return false;
    }
    return true;
};
