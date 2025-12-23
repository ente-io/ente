const baseConfig = require("ente-base/next.config.base.js");

/** @type {import("next").NextConfig} */
module.exports = {
    ...baseConfig,
    headers: async () => {
        const baseHeaders =
            typeof baseConfig.headers === "function"
                ? await baseConfig.headers()
                : [];

        return baseHeaders;
    },
};
