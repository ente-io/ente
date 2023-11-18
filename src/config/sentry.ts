import { isDev } from '../utils/common';
import { APP_ENV } from '../constants/env';

export const AppEnv = isDev ? APP_ENV.DEVELOPMENT : APP_ENV.PRODUCTION;

export const SENTRY_RELEASE = require('../../package.json').version;

export const SENTRY_DSN =
    'https://28650eea457d43538bd450b20e3c4efd@sentry.ente.io/8';

export const SENTRY_TUNNEL_URL = 'https://sentry-reporter.ente.io';

const isAppENVDevelopment = AppEnv === APP_ENV.DEVELOPMENT;

export const IS_SENTRY_ENABLED = !isAppENVDevelopment;
