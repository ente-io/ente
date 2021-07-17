import * as Sentry from '@sentry/nextjs';
import { getSentryTunnelUrl } from 'utils/common/apiUtil';
import { getData, LS_KEYS } from 'utils/storage/localStorage';


const SENTRY_DSN = process.env.NEXT_PUBLIC_SENTRY_DSN ?? 'https://860186db60c54c7fbacfe255124958e8@errors.ente.io/4';
const SENTRY_ENV = process.env.NEXT_PUBLIC_SENTRY_ENV ?? 'development';
const userID = getData(LS_KEYS.USER)?.id;

Sentry.setUser({ id: userID });
Sentry.init({
    dsn: SENTRY_DSN,
    enabled: SENTRY_ENV !== 'development',
    environment: SENTRY_ENV,
    release: process.env.SENTRY_RELEASE,
    attachStacktrace: true,
    tunnel: getSentryTunnelUrl(),
    // ...
    // Note: if you want to override the automatic release value, do not set a
    // `release` value here - use the environment variable `SENTRY_RELEASE`, so
    // that it will also get attached to your source maps
});
