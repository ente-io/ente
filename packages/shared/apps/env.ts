import { APP_ENV } from './constants';

export const getAppEnv = () =>
    process.env.NEXT_PUBLIC_APP_ENV ?? APP_ENV.PRODUCTION;

export const isDisableSentryFlagSet = () => {
    return process.env.NEXT_PUBLIC_DISABLE_SENTRY === 'true';
};

export const getSentryRelease = () => process.env.SENTRY_RELEASE;
