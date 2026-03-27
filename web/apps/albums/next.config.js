// @ts-check

const cp = require("child_process");
const path = require("path");

const gitSHA = (() => {
    const result = cp
        .execSync("git rev-parse --short HEAD 2>/dev/null || true", {
            cwd: __dirname,
            encoding: "utf8",
        })
        .trimEnd();
    return result || undefined;
})();

const appName = path.basename(process.cwd());

/** @type {import("next").NextConfig} */
module.exports = {
    output: "export",
    devIndicators: false,
    compiler: { emotion: true },
    env: {
        gitSHA,
        appName,
    },
    webpack: (config, { isServer }) => {
        if (!isServer) {
            config.resolve.fallback.fs = false;
        }

        config.ignoreWarnings = [{ module: /libheif-js/ }];
        config.experiments = { ...config.experiments, asyncWebAssembly: true };
        config.output = config.output || {};
        config.output.environment = {
            ...(config.output.environment || {}),
            asyncFunction: true,
        };

        return config;
    },
};
