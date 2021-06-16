import * as Sentry from '@sentry/nextjs';

export const logError = (e: any, msg?: string) => {
    Sentry.captureException(e, {
        level: Sentry.Severity.Info,
        contexts: {
            context: {
                message: msg,
            },
        },
    });
};
