import * as Sentry from '@sentry/nextjs';
import { getUserAnonymizedID } from 'utils/user';


export const logError = (e: any, msg?: string) => {
    Sentry.captureException(e, {
        level: Sentry.Severity.Info,
        user: { id: getUserAnonymizedID() },
        contexts: {
            context: {
                message: msg,
            },
        },
    });
};
