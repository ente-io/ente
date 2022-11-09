import * as Sentry from '@sentry/electron/dist/main';
import { makeID } from '../utils/logging';
import { keysStore } from '../stores/keys.store';
import { SENTRY_DSN, RELEASE_VERSION } from '../config';
import { isDev } from '../utils/common';
import { logToDisk } from './logging';

const ENV_DEVELOPMENT = 'development';

const isDEVSentryENV = () =>
    process.env.NEXT_PUBLIC_SENTRY_ENV === ENV_DEVELOPMENT;

export function initSentry(): void {
    Sentry.init({
        dsn: SENTRY_DSN,
        release: RELEASE_VERSION,
        environment: isDev ? 'development' : 'production',
    });
}

export function logErrorSentry(
    error: any,
    msg: string,
    info?: Record<string, unknown>
) {
    const err = errorWithContext(error, msg);
    logToDisk(
        `error: ${error?.name} ${error?.message} ${
            error?.stack
        } msg: ${msg} info: ${JSON.stringify(info)}`
    );
    if (isDEVSentryENV()) {
        console.log(error, { msg, info });
    }
    Sentry.captureException(err, {
        level: Sentry.Severity.Info,
        user: { id: getSentryUserID() },
        contexts: {
            ...(info && {
                info: info,
            }),
            rootCause: { message: error?.message },
        },
    });
}

function errorWithContext(originalError: Error, context: string) {
    const errorWithContext = new Error(context);
    errorWithContext.stack =
        errorWithContext.stack.split('\n').slice(2, 4).join('\n') +
        '\n' +
        originalError.stack;
    return errorWithContext;
}

export function getSentryUserID() {
    let anonymizeUserID = keysStore.get('AnonymizeUserID')?.id;
    if (!anonymizeUserID) {
        anonymizeUserID = makeID(6);
        keysStore.set('AnonymizeUserID', { id: anonymizeUserID });
    }
    return anonymizeUserID;
}
