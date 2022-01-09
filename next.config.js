const withBundleAnalyzer = require('@next/bundle-analyzer')({
    enabled: process.env.ANALYZE === 'true',
});
const withWorkbox = require('@ente-io/next-with-workbox');

const { withSentryConfig } = require('@sentry/nextjs');

const {
    getGitSha,
    convertToNextHeaderFormat,
    buildCSPHeader,
    COOP_COEP_HEADERS,
    WEB_SECURITY_HEADERS,
    CSP_DIRECTIVES,
    WORKBOX_CONFIG,
    ALL_ROUTES,
    getIsSentryEnabled,
} = require('./configUtil');

const GIT_SHA = getGitSha();

const IS_SENTRY_ENABLED = getIsSentryEnabled();

module.exports = withSentryConfig(
    withWorkbox(
        withBundleAnalyzer({
            env: {
                SENTRY_RELEASE: GIT_SHA,
            },
            workbox: WORKBOX_CONFIG,

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
        dryRun: !IS_SENTRY_ENABLED,
    }
);
