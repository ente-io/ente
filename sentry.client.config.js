import * as Sentry from '@sentry/nextjs';
import { getSentryTunnelUrl } from 'utils/common/apiUtil';
import { getUserAnonymizedID } from 'utils/user';
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

Sentry.setUser({ id: getUserAnonymizedID() });
Sentry.init({
    dsn: SENTRY_DSN,
    enabled: ENABLED,
    environment: SENTRY_ENV,
    release: SENTRY_RELEASE,
    attachStacktrace: true,
    autoSessionTracking: false,
    tunnel: getSentryTunnelUrl(),
    // ...
    // Note: if you want to override the automatic release value, do not set a
    // `release` value here - use the environment variable `SENTRY_RELEASE`, so
    // that it will also get attached to your source maps
});
