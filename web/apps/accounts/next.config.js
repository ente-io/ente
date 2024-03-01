const nextConfigBase = require("@/next/next.config.base.js");

module.exports = {
    ...nextConfigBase,
    images: {
        unoptimized: true,
    },
    experimental: {
        externalDir: true,
    },
};
