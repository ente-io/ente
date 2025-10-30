const baseConfig = require("ente-base/next.config.base.js");

module.exports = {
    ...baseConfig,
    async rewrites() {
        return [{ source: "/:token", destination: "/" }];
    },
};
