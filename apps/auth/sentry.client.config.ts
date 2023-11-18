import { setupSentry } from '@ente/shared/sentry/config/sentry.config.base';

const DEFAULT_SENTRY_DSN =
    'https://e2ccc39d811640b49602323774220955@sentry.ente.io/13';

setupSentry(DEFAULT_SENTRY_DSN);
