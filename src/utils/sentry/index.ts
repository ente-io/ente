import * as Sentry from '@sentry/nextjs';
import { addLogLine } from 'utils/logging';
import { getUserAnonymizedID } from 'utils/user';

export const logError = (
    error: any,
    msg: string,
    info?: Record<string, unknown>
) => {
    if (isErrorUnnecessaryForSentry(error)) {
        return;
    }
    const err = errorWithContext(error, msg);
    addLogLine(`error: ${error} msg: ${msg} info: ${info}`);
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
            rootCause: { message: error?.message, completeError: error },
        },
    });
};

// copy of errorWithContext to prevent importing error util
function errorWithContext(originalError: Error, context: string) {
    const errorWithContext = new Error(context);
    errorWithContext.stack =
        errorWithContext.stack.split('\n').slice(2, 4).join('\n') +
        '\n' +
        originalError.stack;
    return errorWithContext;
}

function isErrorUnnecessaryForSentry(error: any) {
    if (error?.message?.includes('Network Error')) {
        return true;
    } else if (error?.status === 401) {
        return true;
    }
    return false;
}
