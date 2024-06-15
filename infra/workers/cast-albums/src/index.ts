/** Proxy file and thumbnail requests from the cast web app */

export default {
    async fetch(request: Request) {
        switch (request.method) {
            case "GET":
                return handleGET(request);
            case "OPTIONS":
                return handleOPTIONS(request);
            default:
                throw new Error(`Unsupported HTTP method ${request.method}`);
        }
    },
} satisfies ExportedHandler;

const handleGET = async (request: Request) => {
    const url = new URL(request.url);
    const castToken =
        request.headers.get("X-Cast-Access-Token") ??
        url.searchParams.get("castToken");
    if (!castToken) throw new Error("No cast token provided");

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

const handleOPTIONS = (request: Request) => {
    let corsHeaders: Record<string, string> = {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "GET, OPTIONS",
        "Access-Control-Max-Age": "86400",
    };

    const acrh = request.headers.get("Access-Control-Request-Headers");
    if (acrh) {
        corsHeaders["Access-Control-Allow-Headers"] = acrh;
    }

    return new Response("", { headers: corsHeaders });
};
