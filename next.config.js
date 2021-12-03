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
const { SubresourceIntegrityPlugin } = require('webpack-subresource-integrity');

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

            // added header for local testing only as they are not exported with the app
            headers() {
                return [
                    {
                        // Apply these headers to all routes in your application....
                        source: '/(.*)',
                        headers: [
                            ...createSecureHeaders({
                                contentSecurityPolicy: {
                                    directives: {
                                        defaultSrc: "'none'",
                                        imgSrc: "'self' blob:",
                                        styleSrc: "'self' 'unsafe-inline'",
                                        fontSrc: "'self'",
                                        scriptSrc: "'self' 'unsafe-eval'",
                                        connectSrc:
                                            "'self' https://api.ente.io data:",
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
                config.output.crossOriginLoading = 'anonymous';
                config.plugins = config.plugins || [];
                config.plugins.push(new SubresourceIntegrityPlugin());
                return config;
            },
        })
    ),
    { release: gitSha }
);
