const ENV_DEVELOPMENT = 'development';
const ENV_PRODUCTION = 'production';
const ENV_TEST = 'test';

module.exports = {
    ENV_DEVELOPMENT,
    ENV_PRODUCTION,
    ENV_TEST,
};

module.exports.getAppEnv = () => {
    return process.env.NEXT_PUBLIC_APP_ENV ?? ENV_PRODUCTION;
};

module.exports.isDisableSentryFlagSet = () => {
    return process.env.NEXT_PUBLIC_DISABLE_SENTRY === 'true';
};
