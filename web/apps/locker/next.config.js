const baseConfig = require("ente-base/next.config.base.js");

const nextConfig = { ...baseConfig };

if (process.env.NODE_ENV !== "production" && !process.env._ENTE_IS_DESKTOP) {
    nextConfig.distDir = ".next-dev";
}

module.exports = nextConfig;
