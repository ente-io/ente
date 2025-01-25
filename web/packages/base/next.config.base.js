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
const path = require("path");
const fs = require("fs");

/**
 * Return the current commit ID if we're running inside a git repository.
 */
const gitSHA = (() => {
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
})();

/**
 * The name of the Ente app we're building.
 *
 * This is taken from the name of the directory which we're building. e.g. `yarn
 * dev:auth` will cause yarn to be invoked in `web/apps/auth`, and so this will
 * be set to `auth`.
 *
 * In our runtime code, all references to `process.env.appName` will be
 * statically replaced by this value at build time.
 */
const appName = path.basename(process.cwd());

/**
 * "1" if we're building our desktop app.
 *
 * The _ENTE_IS_DESKTOP environment variable will be set by the yarn script that
 * builds the web app for embedding in the desktop app. Whenever it is set, we
 * set this value to "1".
 *
 * In our runtime code, all references to `process.env.isDesktop` will be
 * statically replaced by this value at build time.
 */
const isDesktop = process.env._ENTE_IS_DESKTOP ? "1" : "";

/**
 * When we're running within the desktop app, also extract the version of the
 * desktop app for use in our "X-Client-Package" string.
 *
 * > The web app has continuous deployments, and doesn't have versions.
 */
const desktopAppVersion = isDesktop
    ? JSON.parse(fs.readFileSync("../../../desktop/package.json", "utf-8"))
          .version
    : undefined;

// Fail the build if the user is setting any of the legacy environment variables
// which have now been replaced with museum configuration. This is meant to help
// self hosters find the new setting instead of being caught unawares.

if (process.env.NEXT_PUBLIC_ENTE_ACCOUNTS_URL) {
    console.log(
        "The NEXT_PUBLIC_ENTE_ACCOUNTS_URL environment variable is not supported.",
    );
    console.log("Use apps.accounts in the museum configuration instead.");
    process.exit(1);
}

if (process.env.NEXT_PUBLIC_ENTE_FAMILY_URL) {
    console.log(
        "The NEXT_PUBLIC_ENTE_FAMILY_URL environment variable is not supported.",
    );
    console.log("Use apps.family in the museum configuration instead.");
    process.exit(1);
}

/**
 * Configuration for the Next.js build
 *
 * @type {import("next").NextConfig}
 */
const nextConfig = {
    // Generate a static export when we run `next build`.
    output: "export",
    compiler: {
        emotion: true,
    },
    // Use Next.js to transpile our internal packages before bundling them.
    transpilePackages: ["@/base", "@/utils", "@/new"],

    // Add environment variables to the JavaScript bundle. They will be
    // available as `process.env.varName` to our code.
    env: {
        gitSHA,
        appName,
        isDesktop,
        desktopAppVersion,
    },

    // Customize the webpack configuration used by Next.js.
    webpack: (config, { isServer }) => {
        // https://dev.to/marcinwosinek/how-to-add-resolve-fallback-to-webpack-5-in-nextjs-10-i6j
        if (!isServer) {
            config.resolve.fallback.fs = false;
        }

        // Suppress the warning "Critical dependency: require function is used
        // in a way in which dependencies cannot be statically extracted" when
        // import heic-convert.
        //
        // Upstream issue, which currently doesn't have a workaround.
        // https://github.com/catdad-experiments/libheif-js/issues/23
        config.ignoreWarnings = [{ module: /libheif-js/ }];

        return config;
    },
};

module.exports = nextConfig;
