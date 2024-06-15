/** Proxy file and thumbnail requests for the cast web app */

export default {
    async fetch(request: Request) {
        switch (request.method) {
            case "OPTIONS":
                return handleOPTIONS();
            case "GET":
                return handleGET(request);
            default:
                throw new Error(`Unsupported HTTP method ${request.method}`);
        }
    },
} satisfies ExportedHandler;

const handleOPTIONS = () => {
    return new Response("", {
        headers: {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, OPTIONS",
            "Access-Control-Max-Age": "86400",
            "Access-Control-Allow-Headers": "X-Cast-Access-Token",
        },
    });
};

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
