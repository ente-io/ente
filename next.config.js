const withBundleAnalyzer = require('@next/bundle-analyzer')({
    enabled: process.env.ANALYZE === 'true',
});

const { withSentryConfig } = require('@sentry/nextjs');
const { PHASE_DEVELOPMENT_SERVER } = require('next/constants');

const withTM = require('next-transpile-modules')([
    '@mui/material',
    '@mui/system',
    '@mui/icons-material',
]);

const {
    getGitSha,
    convertToNextHeaderFormat,
    buildCSPHeader,
    COOP_COEP_HEADERS,
    WEB_SECURITY_HEADERS,
    CSP_DIRECTIVES,
    ALL_ROUTES,
    getIsSentryEnabled,
} = require('./configUtil');

const GIT_SHA = getGitSha();

const IS_SENTRY_ENABLED = getIsSentryEnabled();

module.exports = (phase) =>
    withSentryConfig(
        withBundleAnalyzer(
            withTM({
                experimental: {
                    esmExternals: false,
                },
                compiler: {
                    styledComponents: {
                        ssr: true,
                        displayName: true,
                    },
                },
                env: {
                    SENTRY_RELEASE: GIT_SHA,
                },

                headers() {
                    return [
                        {
                            // Apply these headers to all routes in your application....
                            source: ALL_ROUTES,
                            headers: convertToNextHeaderFormat({
                                ...COOP_COEP_HEADERS,
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
            })
        ),
        {
            release: GIT_SHA,
            dryRun: phase === PHASE_DEVELOPMENT_SERVER || !IS_SENTRY_ENABLED,
        }
    );
