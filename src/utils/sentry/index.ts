import * as Sentry from '@sentry/nextjs';
import { getUserAnonymizedID } from 'utils/user';

export const logError = (
    e: any,
    msg?: string,
    info?: Record<string, unknown>
) => {
    Sentry.captureException(e, {
        level: Sentry.Severity.Info,
        user: { id: getUserAnonymizedID() },
        contexts: {
            ...(msg && {
                context: {
                    message: msg,
                },
            }),
            ...(info && {
                info: info,
            }),
        },
    });
};
