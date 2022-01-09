const cp = require('child_process');
const { getIsSentryEnabled } = require('./sentryConfigUtil');

module.exports = {
    COOP_COEP_HEADERS: {
        'Cross-Origin-Opener-Policy': 'same-origin',
        'Cross-Origin-Embedder-Policy': 'require-corp',
    },

    WEB_SECURITY_HEADERS: {
        'Strict-Transport-Security': '  max-age=63072000',
        'X-Content-Type-Options': 'nosniff',
        'X-Download-Options': 'noopen',
        'X-Frame-Options': 'deny',
        'X-XSS-Protection': '1; mode=block',
        'Referrer-Policy': 'same-origin',
    },

    CSP_DIRECTIVES: {
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
    },

    WORKBOX_CONFIG: {
        swSrc: 'src/serviceWorker.js',
        exclude: [/manifest\.json$/i],
    },

    ALL_ROUTES: '/(.*)',

    buildCSPHeader: (directives) => ({
        'Content-Security-Policy-Report-Only': Object.entries(
            directives
        ).reduce((acc, [key, value]) => acc + `${key} ${value};`, ''),
    }),

    convertToNextHeaderFormat: (headers) =>
        Object.entries(headers).map(([key, value]) => ({ key, value })),

    getGitSha: () =>
        cp.execSync('git rev-parse --short HEAD', {
            cwd: __dirname,
            encoding: 'utf8',
        }),
    getIsSentryEnabled: getIsSentryEnabled,
};
