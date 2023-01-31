import * as Sentry from '@sentry/nextjs';
import { isDEVSentryENV } from 'constants/sentry';
import { addLogLine } from 'utils/logging';
import { getSentryUserID } from 'utils/user';

export const logError = async (
    error: any,
    msg: string,
    info?: Record<string, unknown>,
    skipAddLogLine = false
) => {
    if (isErrorUnnecessaryForSentry(error)) {
        return;
    }
    const err = errorWithContext(error, msg);
    if (!skipAddLogLine) {
        addLogLine(
            `error: ${error?.name} ${error?.message} ${
                error?.stack
            } msg: ${msg} info: ${JSON.stringify(info)}`
        );
    }
    if (isDEVSentryENV()) {
        addLogLine(error, { msg, info });
    }
    Sentry.captureException(err, {
        level: Sentry.Severity.Info,
        user: { id: await getSentryUserID() },
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
