import * as Sentry from '@sentry/nextjs';

const SENTRY_DSN = process.env.SENTRY_DSN ?? 'https://860186db60c54c7fbacfe255124958e8@errors.ente.io/4';
const SENTRY_ENV = process.env.SENTRY_ENV ?? 'development';

Sentry.init({
    dsn: SENTRY_DSN,
    enabled: SENTRY_ENV !== 'development',
    release: process.env.SENTRY_RELEASE,
    attachStacktrace: true,
    debug: true,
    autoSessionTracking: false,
    // ...
    // Note: if you want to override the automatic release value, do not set a
    // `release` value here - use the environment variable `SENTRY_RELEASE`, so
    // that it will also get attached to your source maps
});
