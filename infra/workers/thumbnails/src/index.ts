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
    return new Response("", {
        headers: {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, OPTIONS",
            "Access-Control-Allow-Headers":
                "X-Auth-Token, X-Client-Package, X-Client-Version",
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

    const headers = {
        "X-Client-Package": request.headers.get("X-Client-Package") ?? "",
        "X-Client-Version": request.headers.get("X-Client-Version") ?? "",
        "User-Agent": request.headers.get("User-Agent") ?? "",
    };

    let response = await fetch(
        `https://api.ente.io/files/preview/${fileID}?${params.toString()}`,
        { headers },
    );

    if (!response.ok) console.log("Upstream error", response.status);

    response = new Response(response.body, response);
    response.headers.set("Access-Control-Allow-Origin", "*");
    hardenResponseHeaders(response.headers);
    return response;
};

const hardenResponseHeaders = (headers: Headers) => {
    headers.set("X-Content-Type-Options", "nosniff");
    headers.set("Content-Security-Policy", "sandbox allow-downloads");
    headers.set("X-Frame-Options", "DENY");
    headers.set("Referrer-Policy", "no-referrer");

    const contentType = headers.get("Content-Type");
    if (contentType && isHTMLLikeContentType(contentType)) {
        enforceAttachmentDisposition(headers);
    }
};

const isHTMLLikeContentType = (contentType: string) => {
    const normalized = contentType.split(";")[0]?.trim().toLowerCase();
    if (!normalized) return false;
    return (
        normalized === "text/html" ||
        normalized === "application/xhtml+xml" ||
        normalized === "image/svg+xml" ||
        normalized === "text/xml" ||
        normalized === "application/xml"
    );
};

const enforceAttachmentDisposition = (headers: Headers) => {
    const contentDisposition = headers.get("Content-Disposition");
    if (contentDisposition && /attachment/i.test(contentDisposition)) {
        return;
    }

    const filenameParams = contentDisposition
        ?.split(";")
        .map((part) => part.trim())
        .filter((part, index) => {
            if (index === 0) return false;
            return /^filename/i.test(part);
        });

    const disposition = ["attachment", ...(filenameParams ?? [])].join("; ");
    headers.set("Content-Disposition", disposition);
};
