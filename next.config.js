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

const COOP_COEP_HEADERS = {
    'Cross-Origin-Opener-Policy': 'same-origin',
    'Cross-Origin-Embedder-Policy': 'require-corp',
};

const WEB_SECURITY_HEADERS = {
    'Strict-Transport-Security': '  max-age=63072000',
    'X-Content-Type-Options': 'nosniff',
    'X-Download-Options': 'noopen',
    'X-Frame-Options': 'deny',
    'X-XSS-Protection': '1; mode=block',
    'Referrer-Policy': 'same-origin',
};

const CSP_DIRECTIVES = {
    'default-src': "'none'",
    'img-src': "'self' blob:",
    'style-src': "'self' 'unsafe-inline'",
    'font-src ': "'self'; script-src 'self' 'unsafe-eval' blob:",
    'connect-src':
        "'self' https://*.ente.io data: blob: https://ente-prod-eu.s3.eu-central-003.backblazeb2.com ",
    'base-uri ': "'self'",
    'frame-ancestors': " 'none'",
    'form-action': "'none'",
    'report-uri': 'https://csp-reporter.ente.io',
    'report-to': 'https://csp-reporter.ente.io',
};

const buildCSPHeader = (directives) => ({
    'Content-Security-Policy-Report-Only': Object.entries(directives).reduce(
        (acc, [key, value]) => acc + `${key} ${value};`,
        ''
    ),
});

const convertToNextHeaderFormat = (headers) =>
    Object.entries(headers).map(([key, value]) => ({ key, value }));

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

            headers() {
                return [
                    {
                        // Apply these headers to all routes in your application....
                        source: '/(.*)',
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
    { release: gitSha }
);
