import * as Sentry from '@sentry/nextjs';
import { addLocalLog, addLogLine } from 'utils/logging';
import { getSentryUserID } from 'utils/user';
import InMemoryStore, { MS_KEYS } from 'services/InMemoryStore';
import { getHasOptedOutOfCrashReports } from 'utils/storage';
import { ApiError } from 'utils/error';

export const logError = async (
    error: any,
    msg: string,
    info?: Record<string, unknown>,
    skipAddLogLine = false
) => {
    const err = errorWithContext(error, msg);
    if (!skipAddLogLine) {
        if (error instanceof ApiError) {
            addLogLine(`error: ${error?.name} ${error?.message} 
            msg: ${msg} errorCode: ${JSON.stringify(error?.errCode)}
            httpStatusCode: ${JSON.stringify(error?.httpStatusCode)} ${
                info ? `info: ${JSON.stringify(info)}` : ''
            }
            ${error?.stack}`);
        } else {
            addLogLine(
                `error: ${error?.name} ${error?.message} 
                msg: ${msg} ${info ? `info: ${JSON.stringify(info)}` : ''}
                ${error?.stack}`
            );
        }
    }
    if (!InMemoryStore.has(MS_KEYS.OPT_OUT_OF_CRASH_REPORTS)) {
        const optedOutOfCrashReports = getHasOptedOutOfCrashReports();
        InMemoryStore.set(
            MS_KEYS.OPT_OUT_OF_CRASH_REPORTS,
            optedOutOfCrashReports
        );
    }
    if (InMemoryStore.get(MS_KEYS.OPT_OUT_OF_CRASH_REPORTS)) {
        addLocalLog(() => `skipping sentry error: ${error?.name}`);
        return;
    }
    if (isErrorUnnecessaryForSentry(error)) {
        return;
    }

    Sentry.captureException(err, {
        level: 'info',
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
