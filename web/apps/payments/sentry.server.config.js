// This file configures the initialization of Sentry on the server.
// The config you add here will be used whenever the server handles a request.
// https://docs.sentry.io/platforms/javascript/guides/nextjs/

import * as Sentry from '@sentry/nextjs';

const SENTRY_DSN =
    (process.env.SENTRY_DSN || process.env.NEXT_PUBLIC_SENTRY_DSN) ??
    'https://208e398c28cd4c069c83d7c6e63adef6@sentry.ente.io/6';

const SENTRY_ENV = process.env.NEXT_PUBLIC_SENTRY_ENV ?? 'development';

Sentry.init({
    dsn: SENTRY_DSN,
    enabled: SENTRY_ENV !== 'development',
    environment: SENTRY_ENV,
    // Adjust this value in production, or use tracesSampler for greater control
    tracesSampleRate: 1.0,
    release: process.env.SENTRY_RELEASE,
    autoSessionTracking: false,

    // ...
    // Note: if you want to override the automatic release value, do not set a
    // `release` value here - use the environment variable `SENTRY_RELEASE`, so
    // that it will also get attached to your source maps
});
