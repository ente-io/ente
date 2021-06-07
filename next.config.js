const withBundleAnalyzer = require('@next/bundle-analyzer')({
    enabled: process.env.ANALYZE === 'true',
});
const withWorkbox = require('next-with-workbox');

const { withSentryConfig } = require('@sentry/nextjs');


module.exports = withSentryConfig(withWorkbox(withBundleAnalyzer({
    future: {
        webpack5: true,
    },
    workbox: {
        swSrc: 'src/serviceWorker.js',
        exclude: ['/manifest.json'],
    },
})));
