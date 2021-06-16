import * as Sentry from '@sentry/nextjs';

const SENTRY_DSN = process.env.SENTRY_DSN ?? 'https://860186db60c54c7fbacfe255124958e8@errors.ente.io/4';
const SENTRY_ENV = process.env.SENTRY_ENV ?? 'development';

Sentry.init({
    dsn: SENTRY_DSN,
    enabled: SENTRY_ENV !== 'development',
    environment: SENTRY_ENV,
    release: process.env.SENTRY_RELEASE,
    debug: true,
    autoSessionTracking: false,
});
