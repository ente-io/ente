const withBundleAnalyzer = require('@next/bundle-analyzer')({
    enabled: process.env.ANALYZE === 'true',
});
const withWorkbox = require('@ente-io/next-with-workbox');

const { withSentryConfig } = require('@sentry/nextjs');

const cp = require('child_process');
const gitSha = cp.execSync('git rev-parse --short HEAD', {
    cwd: __dirname,
    encoding: 'utf8',
});

const { createSecureHeaders } = require('next-secure-headers');

const COOP_COEP_HEADERS = [
    {
        key: 'Cross-Origin-Opener-Policy',
        value: 'same-origin',
    },
    {
        key: 'Cross-Origin-Embedder-Policy',
        value: 'require-corp',
    },
];

module.exports = withSentryConfig(
    withWorkbox(
        withBundleAnalyzer({
            env: {
                SENTRY_RELEASE: gitSha,
            },
            workbox: {
                swSrc: 'src/serviceWorker.js',
                exclude: [/manifest\.json$/i],
            },

            // added to enabled shared Array buffer - https://web.dev/coop-coep/
            headers() {
                return [
                    {
                        // Apply these headers to all routes in your application....
                        source: '/(.*)',
                        headers: [
                            ...COOP_COEP_HEADERS,
                            ...createSecureHeaders({
                                contentSecurityPolicy: {
                                    reportOnly: true,
                                    directives: {
                                        defaultSrc: `'self'`,
                                        frameAncestors: `'self'`,
                                        objectSrc: `'none'`,
                                        baseURI: `'self'`,
                                        formAction: `'self'`,
                                        reportURI:
                                            'https://csp-reporter.ente.workers.dev',
                                        reportTo:
                                            'https://csp-reporter.ente.workers.dev',
                                    },
                                },
                            }),
                        ],
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
    { release: gitSha }
);
