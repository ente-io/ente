const baseConfig = require("ente-base/next.config.base.js");

module.exports = {
    ...baseConfig,
    // Override output for development to support rewrites
    // In production, we use static export (inherited from baseConfig)
    ...(process.env.NODE_ENV === "development" && {
        output: undefined, // Remove 'export' mode in development to allow rewrites
        // Add rewrites only in development for SPA routing
        async rewrites() {
            return {
                fallback: [
                    {
                        // Catch all routes except static files and Next.js internals
                        source: "/:path((?!_next|images|favicon.ico).*)",
                        destination: "/",
                    },
                ],
            };
        },
    }),
};
