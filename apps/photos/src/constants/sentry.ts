export const ENV_DEVELOPMENT = 'development';
export const ENV_PRODUCTION = 'production';

export const getSentryDSN = () =>
    process.env.NEXT_PUBLIC_SENTRY_DSN ??
    'https://bd3656fc40d74d5e8f278132817963a3@sentry.ente.io/2';

export const getSentryENV = () =>
    process.env.NEXT_PUBLIC_SENTRY_ENV ?? ENV_PRODUCTION;

export const getSentryRelease = () => process.env.SENTRY_RELEASE;

export { getIsSentryEnabled } from '../../sentryConfigUtil';

export const isDEVSentryENV = () => getSentryENV() === ENV_DEVELOPMENT;
