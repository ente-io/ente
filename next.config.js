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

module.exports = withSentryConfig(withWorkbox(withBundleAnalyzer({
    future: {
        webpack5: true,
    },
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
})), { release: gitSha });
