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

// Strict allowlist of upload destinations. Expand as needed.
const ALLOWED_UPLOAD_HOSTS = new Set<string>([
    // Example: Backblaze B2 S3-compatible bucket endpoint
    "ente-prod-eu.s3.eu-central-003.backblazeb2.com",
]);

const isAllowedUploadURL = (uploadURL: string) => {
    try {
        const url = new URL(uploadURL);
        // Enforce HTTPS, no credentials, and an allowlisted host.
        if (url.protocol !== "https:") return false;
        if (url.username || url.password) return false;
        // Only default HTTPS port; signed URLs should not need a custom port.
        if (url.port && url.port !== "443") return false;
        if (!ALLOWED_UPLOAD_HOSTS.has(url.hostname)) return false;
        return true;
    } catch {
        return false;
    }
};

const handleOPTIONS = (request: Request) => {
    const origin = request.headers.get("Origin");
    if (!isAllowedOrigin(origin)) console.warn("Unknown origin", origin);
    return new Response("", {
        headers: {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "POST, PUT, OPTIONS",
            "Access-Control-Allow-Headers":
                "Content-Type, UPLOAD-URL, X-Client-Package, X-Client-Version",
            "Access-Control-Expose-Headers": "X-Request-Id, CF-Ray",
            "Access-Control-Max-Age": "86400",
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

const handlePOSTOrPUT = async (request: Request) => {
    const url = new URL(request.url);

    const uploadURL = request.headers.get("UPLOAD-URL");
    if (!uploadURL) {
        console.error("No uploadURL provided");
        return new Response(null, { status: 400 });
    }
    if (!isAllowedUploadURL(uploadURL)) {
        console.warn("Blocked uploadURL due to allowlist", uploadURL);
        return new Response(JSON.stringify({ error: "host not whitelisted" }), {
            status: 400,
            headers: {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Expose-Headers": "X-Request-Id, CF-Ray",
            },
        });
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
        "X-Request-Id, CF-Ray",
    );
    return response;
};
