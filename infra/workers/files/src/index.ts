/** Proxy requests for files. */

export default {
    async fetch(request: Request) {
        switch (request.method) {
            // case "OPTIONS":
            //     return handleOPTIONS(request);
            // case "GET":
            //     return handleGET(request);
            default:
                console.log(`Unsupported HTTP method ${request.method}`);
                return new Response(null, { status: 405 });
        }
    },
} satisfies ExportedHandler;
