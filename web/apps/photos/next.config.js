const baseConfig = require("ente-base/next.config.base.js");

/** @type {import("next").NextConfig} */
module.exports = {
    ...baseConfig,
    headers: async () => {
        const baseHeaders =
            typeof baseConfig.headers === "function"
                ? await baseConfig.headers()
                : [];

        return [
            ...baseHeaders,
            {
                source: "/streamsaver/sw.js",
                headers: [
                    { key: "Service-Worker-Allowed", value: "/" },
                    { key: "Cache-Control", value: "no-store, must-revalidate" },
                ],
            },
            {
                source: "/streamsaver/:path*",
                headers: [
                    { key: "Cache-Control", value: "no-store, must-revalidate" },
                ],
            },
        ];
    },
};
