import { APP_ENV } from '../constants/env';

export const getAppEnv = () => process.env.APP_ENV ?? APP_ENV.DEVELOPMENT;

export const isDisableSentryFlagSet = () => {
    return process.env.DISABLE_SENTRY === 'true';
};

export const SENTRY_RELEASE = require('../../package.json').version;

export const SENTRY_DSN =
    'https://28650eea457d43538bd450b20e3c4efd@sentry.ente.io/8';

export const SENTRY_TUNNEL_URL = 'https://sentry-reporter.ente.io';

export const getIsSentryEnabled = () => {
    const isAppENVDevelopment = getAppEnv() === APP_ENV.DEVELOPMENT;
    const isSentryDisabled = isDisableSentryFlagSet();
    return !isAppENVDevelopment && !isSentryDisabled;
};
