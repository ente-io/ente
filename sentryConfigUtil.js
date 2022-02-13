module.exports.getIsSentryEnabled = () => {
    if (process.env.NEXT_PUBLIC_IS_SENTRY_ENABLED) {
        return process.env.NEXT_PUBLIC_IS_SENTRY_ENABLED === 'yes';
    } else {
        if (process.env.NEXT_PUBLIC_SENTRY_ENV) {
            return process.env.NEXT_PUBLIC_SENTRY_ENV !== 'development';
        }
    }
    return false;
};
