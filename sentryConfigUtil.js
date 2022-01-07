module.exports.isSentryEnabled = () =>
    process.env.SENTRY_ENABLED ??
    (process.env.NEXT_PUBLIC_SENTRY_ENV ?? 'development') !== 'development';
