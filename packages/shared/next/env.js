const ENV_DEVELOPMENT = 'development';
const ENV_PRODUCTION = 'production';
const ENV_TEST = 'test';

module.exports = {
    ENV_DEVELOPMENT,
    ENV_PRODUCTION,
    ENV_TEST,
};

module.exports.getAppEnv = () => {
    return process.env.NEXT_PUBLIC_APP_ENV ?? ENV_DEVELOPMENT;
};

module.exports.isEnableSentryFlagSet = () => {
    return process.env.NEXT_PUBLIC_ENABLE_SENTRY === 'true';
};
