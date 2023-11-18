import * as Sentry from '@sentry/electron';
import { makeID } from '../utils/logging';
import { keysStore } from '../stores/keys.store';
import { logToDisk } from './logging';
import { hasOptedOutOfCrashReports } from '../main';
import {
    getAppEnv,
    SENTRY_DSN,
    SENTRY_RELEASE,
    getIsSentryEnabled,
    SENTRY_TUNNEL_URL,
} from '../config/sentry';

export function initSentry(): void {
    const APP_ENV = getAppEnv();
    const IS_ENABLED = getIsSentryEnabled();
    Sentry.init({
        dsn: SENTRY_DSN,
        enabled: IS_ENABLED,
        environment: APP_ENV,
        release: SENTRY_RELEASE,
        attachStacktrace: true,
        autoSessionTracking: false,
        tunnel: SENTRY_TUNNEL_URL,
    });
    Sentry.setUser({ id: getSentryUserID() });
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
    if (hasOptedOutOfCrashReports()) {
        logToDisk(`skipping sentry error: ${error?.name}`);
        return;
    }
    Sentry.captureException(err, {
        level: 'info',
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
