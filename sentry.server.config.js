import * as Sentry from '@sentry/nextjs';
import {
    getSentryDSN,
    getSentryENV,
    getSentryRelease,
    isSentryEnabled,
} from 'constants/sentry';

const SENTRY_DSN = getSentryDSN();
const SENTRY_ENV = getSentryENV();
const SENTRY_RELEASE = getSentryRelease();
const ENABLED = isSentryEnabled();

Sentry.init({
    dsn: SENTRY_DSN,
    enabled: ENABLED,
    environment: SENTRY_ENV,
    release: SENTRY_RELEASE,
    autoSessionTracking: false,
});
