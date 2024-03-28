// This file configures the initialization of Sentry on the browser.
// The config you add here will be used whenever a page is visited.
// https://docs.sentry.io/platforms/javascript/guides/nextjs/

import * as Sentry from '@sentry/nextjs';

const SENTRY_DSN =
    (process.env.SENTRY_DSN || process.env.NEXT_PUBLIC_SENTRY_DSN) ??
    'https://67447bc36684b1f7a18d79683b788f25@sentry.ente.io/6';

const TUNNEL_URL = 'https://sentry-reporter.ente.io';
const SENTRY_ENV = process.env.NEXT_PUBLIC_SENTRY_ENV ?? 'development';

Sentry.init({
    dsn: SENTRY_DSN,
    enabled: false,
    environment: SENTRY_ENV,
    // Adjust this value in production, or use tracesSampler for greater control
    tracesSampleRate: 1.0,
    attachStacktrace: true,
    autoSessionTracking: false,
    tunnel: TUNNEL_URL,
    // ...
    // Note: if you want to override the automatic release value, do not set a
    // `release` value here - use the environment variable `SENTRY_RELEASE`, so
    // that it will also get attached to your source maps
});
