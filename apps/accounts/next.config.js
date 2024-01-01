const nextConfigBase = require('@ente/shared/next/next.config.base.js');

module.exports = {
    ...nextConfigBase,
    images: {
        unoptimized: true,
    },
    experimental: {
        externalDir: true,
    },
};
