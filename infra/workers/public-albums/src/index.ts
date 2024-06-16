/** Proxy requests for files and thumbnails in public albums. */

export default {
    async fetch(request: Request) {
        return new Response(null, { status: 405 });
    },
} satisfies ExportedHandler;
