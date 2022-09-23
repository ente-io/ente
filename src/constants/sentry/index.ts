export const ENV_DEVELOPMENT = 'development';
export const ENV_PRODUCTION = 'production';

export const getSentryDSN = () =>
    process.env.NEXT_PUBLIC_SENTRY_DSN ??
    'https://60abb33b597c42f6a3fb27cd82c55101@sentry.ente.io/2';

export const getSentryENV = () =>
    process.env.NEXT_PUBLIC_SENTRY_ENV ?? ENV_PRODUCTION;

export const getSentryRelease = () => process.env.SENTRY_RELEASE;

export { getIsSentryEnabled } from '../../../sentryConfigUtil';

export const isDEVSentryENV = () => getSentryENV() === ENV_DEVELOPMENT;
