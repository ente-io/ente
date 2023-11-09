const { withSentryConfig } = require('@sentry/nextjs');
const { PHASE_DEVELOPMENT_SERVER } = require('next/constants');

const {
    convertToNextHeaderFormat,
    buildCSPHeader,
    WEB_SECURITY_HEADERS,
    CSP_DIRECTIVES,
    ALL_ROUTES,
} = require('./utils/headers');

const { getGitSha, getIsSentryEnabled } = require('./utils/sentry');

const GIT_SHA = getGitSha();

const IS_SENTRY_ENABLED = getIsSentryEnabled();

module.exports = (phase) =>
    withSentryConfig(
        {
            sentry: {
                widenClientFileUpload: true,
                disableServerWebpackPlugin: true,
                autoInstrumentServerFunctions: false,
            },
            output: 'export',
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
                NEXT_PUBLIC_IS_TEST_APP: process.env.IS_TEST_RELEASE || 'false',
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
        },
        {
            dryRun: phase === PHASE_DEVELOPMENT_SERVER || !IS_SENTRY_ENABLED,
            release: GIT_SHA,
        }
    );
