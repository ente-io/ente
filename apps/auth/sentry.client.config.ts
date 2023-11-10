import { setupSentry } from '@ente/shared/sentry/config/sentry.config.base';

const DEFAULT_SENTRY_DSN =
    'https://9466dbb7dc1e45f7865f16571d5320a9@sentry.ente.io/13';

setupSentry(DEFAULT_SENTRY_DSN);
