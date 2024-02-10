export const isDisableSentryFlagSet = () => {
    return process.env.NEXT_PUBLIC_DISABLE_SENTRY === 'true';
};

export const getSentryRelease = () => process.env.SENTRY_RELEASE;
