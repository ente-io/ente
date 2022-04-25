import * as Sentry from '@sentry/electron/dist/main';

import { keysStore } from '../services/store';
import { isDev } from './common';

const SENTRY_DSN = 'https://e9268b784d1042a7a116f53c58ad2165@sentry.ente.io/5';

// eslint-disable-next-line @typescript-eslint/no-var-requires
const version = require('../../package.json').version;

function initSentry(): void {
    Sentry.init({
        dsn: SENTRY_DSN,
        release: version,
        environment: isDev ? 'development' : 'production',
    });
}

export function logErrorSentry(
    error: any,
    msg: string,
    info?: Record<string, unknown>
) {
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
}

function errorWithContext(originalError: Error, context: string) {
    const errorWithContext = new Error(context);
    errorWithContext.stack =
        errorWithContext.stack.split('\n').slice(2, 4).join('\n') +
        '\n' +
        originalError.stack;
    return errorWithContext;
}

function makeID(length: number) {
    let result = '';
    const characters =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    const charactersLength = characters.length;
    for (let i = 0; i < length; i++) {
        result += characters.charAt(
            Math.floor(Math.random() * charactersLength)
        );
    }
    return result;
}

function getUserAnonymizedID() {
    let anonymizeUserID = keysStore.get('AnonymizeUserID')?.id;
    if (!anonymizeUserID) {
        anonymizeUserID = makeID(6);
        keysStore.set('AnonymizeUserID', { id: anonymizeUserID });
    }
    return anonymizeUserID;
}

export default initSentry;
