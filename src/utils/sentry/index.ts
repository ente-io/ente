import * as Sentry from '@sentry/nextjs';
import { errorWithContext } from 'utils/common/errorUtil';
import { getUserAnonymizedID } from 'utils/user';

export const logError = (
    e: any,
    msg: string,
    info?: Record<string, unknown>
) => {
    const err = errorWithContext(e, msg);
    Sentry.captureException(err, {
        level: Sentry.Severity.Info,
        user: { id: getUserAnonymizedID() },
        contexts: {
            ...(info && {
                info: info,
            }),
        },
    });
};
