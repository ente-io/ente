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
            case "POST":
                return handlePOSTOrPUT(request);
            case "PUT":
                return handlePOSTOrPUT(request);
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
            // "Access-Control-Allow-Headers": "Content-Type", "UPLOAD-URL, X-Client-Package",
            "Access-Control-Allow-Headers": "*",
            "Access-Control-Expose-Headers": "X-Request-Id, CF-Ray",
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
    const allowed = ["content-type", "upload-url", "x-client-package"];

    if (!headers) return true;
    for (const header of headers.split(",")) {
        if (!allowed.includes(header.trim().toLowerCase())) return false;
    }
    return true;
};

const handlePOSTOrPUT = async (request: Request) => {
    const url = new URL(request.url);

    const uploadURL = request.headers.get("UPLOAD-URL");
    if (!uploadURL) {
        console.error("No uploadURL provided");
        return new Response(null, { status: 400 });
    }

    let response: Response;
    switch (url.pathname) {
        case "/file-upload":
            response = await fetch(uploadURL, {
                method: request.method,
                body: request.body,
            });
            break;
        case "/multipart-upload":
            response = await fetch(uploadURL, {
                method: request.method,
                body: request.body,
            });
            if (response.ok) {
                const etag = response.headers.get("etag");
                if (etag === null) {
                    console.log("No etag in response", response);
                    response = new Response(null, { status: 500 });
                } else {
                    response = new Response(JSON.stringify({ etag }));
                }
            }
            break;
        case "/multipart-complete":
            response = await fetch(uploadURL, {
                method: request.method,
                body: request.body,
                headers: {
                    "Content-Type": "text/xml",
                },
            });
            break;
        default:
            return new Response(null, { status: 404 });
    }

    if (!response.ok) console.log("Upstream error", response.status);

    response = new Response(response.body, response);
    response.headers.set("Access-Control-Allow-Origin", "*");
    response.headers.set(
        "Access-Control-Expose-Headers",
        "X-Request-Id, CF-Ray"
    );
    return response;
};
