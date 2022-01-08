module.exports.isSentryEnabled = () => {
    if (process.env.SENTRY_ENABLED) {
        return process.env.SENTRY_ENABLED === 'yes';
    } else {
        if (process.env.NEXT_PUBLIC_SENTRY_ENV) {
            return process.env.NEXT_PUBLIC_SENTRY_ENV !== 'development';
        }
    }
    return false;
};
