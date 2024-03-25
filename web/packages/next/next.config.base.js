// @ts-check

/**
 * @file Configure the Next.js build
 *
 * This file gets used by the Next.js build phase, and is not included in the
 * browser build. It will not be parsed by Webpack, Babel or TypeScript, so
 * don't use features that will not be available in our target node version.
 *
 * https://nextjs.org/docs/pages/api-reference/next-config-js
 */

const cp = require("child_process");
const os = require("os");

/**
 * Return the current commit ID if we're running inside a git repository.
 */
const gitSHA = () => {
    // Allow the command to fail. gitSHA will be an empty string in such cases.
    // This allows us to run the build even when we're outside of a git context.
    //
    // The /dev/null redirection is needed so that we don't print error messages
    // if someone is trying to run outside of a git context. Since the way to
    // redirect output and ignore failure is different on Windows, the command
    // needs to be OS specific.
    const command =
        os.platform() == "win32"
            ? "git rev-parse --short HEAD 2> NUL || cd ."
            : "git rev-parse --short HEAD 2>/dev/null || true";
    const result = cp
        .execSync(command, {
            cwd: __dirname,
            encoding: "utf8",
        })
        .trimEnd();
    // Convert empty strings (e.g. when the `|| true` part of the above execSync
    // comes into play) to undefined.
    return result ? result : undefined;
};

/**
 * Configuration for the Next.js build
 *
 * @type {import("next").NextConfig}
 */
const nextConfig = {
    /* generate a static export when we run `next build` */
    output: "export",
    compiler: {
        emotion: true,
    },
    transpilePackages: [
        "@/next",
        "@/ui",
        "@/utils",
        "@mui/material",
        "@mui/system",
        "@mui/icons-material",
    ],

    // Add environment variables to the JavaScript bundle. They will be
    // available as `process.env.VAR_NAME` to our code.
    env: {
        GIT_SHA: gitSHA(),
    },

    // https://dev.to/marcinwosinek/how-to-add-resolve-fallback-to-webpack-5-in-nextjs-10-i6j
    webpack: (config, { isServer }) => {
        if (!isServer) {
            config.resolve.fallback.fs = false;
        }
        return config;
    },
};

module.exports = nextConfig;
