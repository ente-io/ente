import { setupSentry } from '@ente/shared/sentry/config/sentry.config.base';

const DEFAULT_SENTRY_DSN =
    'https://bd3656fc40d74d5e8f278132817963a3@sentry.ente.io/2';
setupSentry(DEFAULT_SENTRY_DSN);
