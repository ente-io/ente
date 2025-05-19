/**
 * Log CSP reports.
 *
 * See _headers in the web app source.
 */

export default {
    async fetch(request: Request) {
        switch (request.method) {
            case "POST":
                return handlePOST(request);
            default:
                console.log(`Unsupported HTTP method ${request.method}`);
                return new Response(null, { status: 405 });
        }
    },
} satisfies ExportedHandler;

const handlePOST = async (request: Request) => {
    console.log("[csp-report]", await request.text());
    return new Response(null, { status: 200 });
};
