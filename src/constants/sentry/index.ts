export const getSentryDSN = () =>
    process.env.NEXT_PUBLIC_SENTRY_DSN ??
    'https://860186db60c54c7fbacfe255124958e8@errors.ente.io/4';

export const getSentryENV = () =>
    process.env.NEXT_PUBLIC_SENTRY_ENV ?? 'development';

export const getSentryRelease = () => process.env.SENTRY_RELEASE;

export const isSentryEnabled = () =>
    process.env.SENTRY_ENABLED ??
    (process.env.NEXT_PUBLIC_SENTRY_ENV ?? 'development') !== 'development';
