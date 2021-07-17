import * as Sentry from '@sentry/nextjs';
import { getData, LS_KEYS } from 'utils/storage/localStorage';

export const logError = (e: any, msg?: string) => {
    const userID = getData(LS_KEYS.USER)?.id;
    Sentry.captureException(e, {
        level: Sentry.Severity.Info,
        user: { id: userID },
        contexts: {
            context: {
                message: msg,
            },
        },
    });
};
