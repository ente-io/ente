const baseConfig = require("ente-base/next.config.base.js");

module.exports = {
    ...baseConfig,
    // Disable file tracing for the share app to avoid build errors
    outputFileTracingRoot: undefined,
    experimental: {
        ...baseConfig.experimental,
        outputFileTracingIncludes: undefined,
    },
    // Only add rewrites for development (not for static export)
    async rewrites() {
        // Only apply rewrites in development mode
        if (process.env.NODE_ENV !== "production") {
            return {
                fallback: [
                    {
                        // Catch all routes except static files and Next.js internals
                        source: "/:path((?!_next|images|favicon.ico).*)",
                        destination: "/",
                    },
                ],
            };
        }
        return {
            fallback: [],
        };
    },
};
