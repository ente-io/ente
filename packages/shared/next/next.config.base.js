/**
 * @file Configure the Next.js build
 *
 * This file gets used by the Next.js build phase, and is not included in the
 * browser build. It will not be parsed by Webpack, Babel or TypeScript, so
 * don't use features that will not be available in our target node version.
 *
 * https://nextjs.org/docs/pages/api-reference/next-config-js
 */

const { withSentryConfig } = require('@sentry/nextjs');
const cp = require('child_process');

const gitSHA = cp.execSync('git rev-parse --short HEAD', {
    cwd: __dirname,
    encoding: 'utf8',
});

const nextConfig = {
    compiler: {
        emotion: {
            importMap: {
                '@mui/material': {
                    styled: {
                        canonicalImport: ['@emotion/styled', 'default'],
                        styledBaseImport: ['@mui/material', 'styled'],
                    },
                },
                '@mui/material/styles': {
                    styled: {
                        canonicalImport: ['@emotion/styled', 'default'],
                        styledBaseImport: ['@mui/material/styles', 'styled'],
                    },
                },
            },
        },
    },
    transpilePackages: [
        "@repo/ui",
        '@ente-io/utils',
        '@mui/material',
        '@mui/system',
        '@mui/icons-material',
    ],

    // Add environment variables to the JavaScript bundle. They will be
    // available as `process.env.VAR_NAME` to our code.
    env: {
        GIT_SHA: gitSHA,
    },

    // https://dev.to/marcinwosinek/how-to-add-resolve-fallback-to-webpack-5-in-nextjs-10-i6j
    webpack: (config, { isServer }) => {
        if (!isServer) {
            config.resolve.fallback.fs = false;
        }
        return config;
    },

    // Build time Sentry configuration
    // https://docs.sentry.io/platforms/javascript/guides/nextjs/manual-setup/
    sentry: {
        widenClientFileUpload: true,
        disableServerWebpackPlugin: true,
    },
};

const sentryWebpackPluginOptions = {};

// withSentryConfig extends the default Next.js usage of webpack to:
//
// 1. Initialize the SDK on client page load (See `sentry.client.config.ts`)
//
// 2. Upload sourcemaps, using the settings defined in `sentry.properties`.
//    Sourcemaps are only uploaded if SENTRY_AUTH_TOKEN is defined.
//
// Irritatingly, Sentry insists that we create empty sentry.server.config.ts and
// sentry.edge.config.ts files, even though we are not using those parts.
module.exports = withSentryConfig(nextConfig, sentryWebpackPluginOptions);
