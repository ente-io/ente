import * as Sentry from '@sentry/nextjs';
import {
    getSentryDSN,
    getSentryENV,
    getSentryRelease,
    getIsSentryEnabled,
} from 'constants/sentry';

const SENTRY_DSN = getSentryDSN();
const SENTRY_ENV = getSentryENV();
const SENTRY_RELEASE = getSentryRelease();
const IS_ENABLED = getIsSentryEnabled();

Sentry.init({
    dsn: SENTRY_DSN,
    enabled: IS_ENABLED,
    environment: SENTRY_ENV,
    release: SENTRY_RELEASE,
    autoSessionTracking: false,
});
