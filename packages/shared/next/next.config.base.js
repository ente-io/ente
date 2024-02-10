const { withSentryConfig } = require('@sentry/nextjs');
const { PHASE_DEVELOPMENT_SERVER } = require('next/constants');
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
    transpilePackages: ['@mui/material', '@mui/system', '@mui/icons-material'],

    // https://dev.to/marcinwosinek/how-to-add-resolve-fallback-to-webpack-5-in-nextjs-10-i6j
    webpack: (config, { isServer }) => {
        if (!isServer) {
            config.resolve.fallback.fs = false;
        }
        return config;
    },

    // Build time Sentry configuration
    sentry: {
        widenClientFileUpload: true,
        disableServerWebpackPlugin: true,
    },
};

// https://docs.sentry.io/platforms/javascript/guides/nextjs/manual-setup/
const createSentryWebpackPluginOptions = (phase) => {
    return {
        dryRun: phase === PHASE_DEVELOPMENT_SERVER,
        release: gitSHA,
    };
};

// withSentryConfig extends the default Next.js usage of webpack to
// 1. Initialize the SDK on client page load (`sentry.client.config.ts`)
// 2. Upload sourcemaps (using the settings defined in `.sentryclirc`)
module.exports = (phase) =>
    withSentryConfig(nextConfig, createSentryWebpackPluginOptions(phase));
