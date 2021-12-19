import * as Sentry from '@sentry/nextjs';
import { errorWithContext } from 'utils/common/errorUtil';
import { getUserAnonymizedID } from 'utils/user';

export const logError = (
    error: any,
    msg: string,
    info?: Record<string, unknown>
) => {
    const err = errorWithContext(error, msg);
    if (!process.env.NEXT_PUBLIC_SENTRY_ENV) {
        console.log(error, { msg, info });
    }
    Sentry.captureException(err, {
        level: Sentry.Severity.Info,
        user: { id: getUserAnonymizedID() },
        contexts: {
            ...(info && {
                info: info,
            }),
            rootCause: { message: error?.message },
        },
    });
};
