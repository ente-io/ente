/** Proxy file and thumbnail requests for the cast web app. */

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
            "Access-Control-Allow-Headers":
                "X-Cast-Access-Token, X-Client-Package, X-Client-Version",
        },
    });
};

const isAllowedOrigin = (origin: string | null) => {
    const allowed = ["cast.ente.io", "cast.ente.sh", "localhost"];

    if (!origin) return false;
    try {
        const url = new URL(origin);
        return allowed.includes(url.hostname);
    } catch {
        // origin is likely an invalid URL
        return false;
    }
};

const handleGET = async (request: Request) => {
    const url = new URL(request.url);

    const fileID = url.searchParams.get("fileID");
    if (!fileID) return new Response(null, { status: 400 });

    let castToken = request.headers.get("X-Cast-Access-Token");
    if (!castToken) {
        console.warn("Using deprecated castToken query param");
        castToken = url.searchParams.get("castToken");
    }

    if (!castToken) {
        console.error("No cast token provided");
        return new Response(null, { status: 400 });
    }

    const pathname = url.pathname;
    const params = new URLSearchParams({ castToken });

    const headers = {
        "X-Client-Package": request.headers.get("X-Client-Package") ?? "",
        "X-Client-Version": request.headers.get("X-Client-Version") ?? "",
        "User-Agent": request.headers.get("User-Agent") ?? "",
    };

    let response = await fetch(
        `https://api.ente.io/cast/files${pathname}${fileID}?${params.toString()}`,
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
