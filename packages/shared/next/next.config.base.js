const { withSentryConfig } = require('@sentry/nextjs');
const { PHASE_DEVELOPMENT_SERVER } = require('next/constants');

const { getGitSha, getIsSentryEnabled } = require('./utils/sentry');

const GIT_SHA = getGitSha();

const IS_SENTRY_ENABLED = getIsSentryEnabled();

module.exports = (phase) =>
    withSentryConfig(
        {
            sentry: {
                widenClientFileUpload: true,
                disableServerWebpackPlugin: true,
                autoInstrumentServerFunctions: false,
            },
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
                                styledBaseImport: [
                                    '@mui/material/styles',
                                    'styled',
                                ],
                            },
                        },
                    },
                },
            },
            transpilePackages: [
                '@mui/material',
                '@mui/system',
                '@mui/icons-material',
            ],
            env: {
                SENTRY_RELEASE: GIT_SHA,
                NEXT_PUBLIC_IS_TEST_APP: process.env.IS_TEST_RELEASE || 'false',
            },

            // https://dev.to/marcinwosinek/how-to-add-resolve-fallback-to-webpack-5-in-nextjs-10-i6j
            webpack: (config, { isServer }) => {
                if (!isServer) {
                    config.resolve.fallback.fs = false;
                }
                return config;
            },
        },
        {
            dryRun: phase === PHASE_DEVELOPMENT_SERVER || !IS_SENTRY_ENABLED,
            release: GIT_SHA,
        }
    );
