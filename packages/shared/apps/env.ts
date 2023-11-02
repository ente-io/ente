import { APP_ENV } from './constants';

export const getAppEnv = () =>
    process.env.NEXT_PUBLIC_APP_ENV ?? APP_ENV.DEVELOPMENT;
