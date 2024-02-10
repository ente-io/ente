const { withSentryConfig } = require('@sentry/nextjs');
const { PHASE_DEVELOPMENT_SERVER } = require('next/constants');

const cp = require('child_process');

const gitSHA = cp.execSync('git rev-parse --short HEAD', {
    cwd: __dirname,
    encoding: 'utf8',
});

module.exports = (phase) =>
    withSentryConfig(
        {
            sentry: {
                widenClientFileUpload: true,
                disableServerWebpackPlugin: true,
                autoInstrumentServerFunctions: false,
            },
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
                // Sentry reads this env var to set the "release" value.
                // TODO(MR): We also set this below, are both places required?
                SENTRY_RELEASE: gitSHA,
            },

            // https://dev.to/marcinwosinek/how-to-add-resolve-fallback-to-webpack-5-in-nextjs-10-i6j
            webpack: (config, { isServer }) => {
                if (!isServer) {
                    config.resolve.fallback.fs = false;
                }
                return config;
            },
        },
        {
            dryRun: phase === PHASE_DEVELOPMENT_SERVER,
            release: gitSHA,
        }
    );
