const ENV_DEVELOPMENT = 'development';

module.exports.getIsSentryEnabled = () => {
    if (process.env.NEXT_PUBLIC_SENTRY_ENV === ENV_DEVELOPMENT) {
        return false;
    } else if (process.env.NEXT_PUBLIC_DISABLE_SENTRY === 'true') {
        return false;
    } else {
        return true;
    }
};
