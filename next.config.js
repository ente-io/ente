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

// eslint-disable-next-line camelcase
const COOP_COEP_Headers = [
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
            webpack: (config) => {
                config.output.hotUpdateMainFilename =
                    'static/webpack/[fullhash].[runtime].hot-update.json';
                return config;
            },

            headers() {
                return [
                    {
                        // Apply these headers to all routes in your application....
                        source: '/(.*)',
                        headers: COOP_COEP_Headers,
                    },
                ];
            },
        })
    ),
    { release: gitSha }
);
