import isElectron from 'is-electron';
import { logError } from '@ente/shared/sentry';
import { getAppEnv } from '../apps/env';
import { APP_ENV } from '../apps/constants';
import { formatLog, logWeb } from './web';
import { WorkerSafeElectronService } from '../electron/service';

export const MAX_LOG_SIZE = 5 * 1024 * 1024; // 5MB
export const MAX_LOG_LINES = 1000;

export function addLogLine(
    log: string | number | boolean,
    ...optionalParams: (string | number | boolean)[]
) {
    try {
        const completeLog = [log, ...optionalParams].join(' ');
        if (getAppEnv() === APP_ENV.DEVELOPMENT) {
            console.log(completeLog);
        }
        if (isElectron()) {
            WorkerSafeElectronService.logToDisk(completeLog);
        } else {
            logWeb(completeLog);
        }
    } catch (e) {
        logError(e, 'failed to addLogLine', undefined, true);
        // ignore
    }
}

export const addLocalLog = (getLog: () => string) => {
    if (getAppEnv() === APP_ENV.DEVELOPMENT) {
        console.log(
            formatLog({
                logLine: getLog(),
                timestamp: Date.now(),
            })
        );
    }
};
