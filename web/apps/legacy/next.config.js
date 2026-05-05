const baseConfig = require("ente-base/next.config.base.js");

module.exports = {
    ...baseConfig,
    transpilePackages: [...(baseConfig.transpilePackages ?? []), "pdfjs-dist"],
};
