const withBundleAnalyzer = require('@next/bundle-analyzer')({
    enabled: process.env.ANALYZE === 'true',
});

const { withSentryConfig } = require('@sentry/nextjs');
const { PHASE_DEVELOPMENT_SERVER } = require('next/constants');

const {
    getGitSha,
    convertToNextHeaderFormat,
    buildCSPHeader,
    WEB_SECURITY_HEADERS,
    CSP_DIRECTIVES,
    ALL_ROUTES,
    getIsSentryEnabled,
} = require('./configUtil');

const GIT_SHA = getGitSha();

const IS_SENTRY_ENABLED = getIsSentryEnabled();

module.exports = (phase) =>
    withSentryConfig(
        withBundleAnalyzer({
            sentry: {
                hideSourceMaps: false,
                widenClientFileUpload: true,
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
                NEXT_PUBLIC_IS_TEST_APP: process.env.IS_TEST_RELEASE,
            },

            headers() {
                return [
                    {
                        // Apply these headers to all routes in your application....
                        source: ALL_ROUTES,
                        headers: convertToNextHeaderFormat({
                            ...WEB_SECURITY_HEADERS,
                            ...buildCSPHeader(CSP_DIRECTIVES),
                        }),
                    },
                ];
            },
            // https://dev.to/marcinwosinek/how-to-add-resolve-fallback-to-webpack-5-in-nextjs-10-i6j
            webpack: (config, { isServer }) => {
                if (!isServer) {
                    config.resolve.fallback.fs = false;
                }
                return config;
            },
        }),
        {
            release: GIT_SHA,
            dryRun: phase === PHASE_DEVELOPMENT_SERVER || !IS_SENTRY_ENABLED,
        }
    );
