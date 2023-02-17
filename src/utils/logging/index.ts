import { ElectronFile } from 'types/upload';
import { convertBytesToHumanReadable } from 'utils/file/size';
import { formatDateTimeShort } from 'utils/time/format';
import { isDEVSentryENV } from 'constants/sentry';
import isElectron from 'is-electron';
import ElectronService from 'services/electron/common';
import { logError } from 'utils/sentry';
import {
    getData,
    LS_KEYS,
    removeData,
    setData,
} from 'utils/storage/localStorage';

export const MAX_LOG_SIZE = 5 * 1024 * 1024; // 5MB
export const MAX_LOG_LINES = 1000;

export interface Log {
    timestamp: number;
    logLine: string;
}

export function addLogLine(
    log: string | number | boolean,
    ...optionalParams: (string | number | boolean)[]
) {
    try {
        const completeLog = [log, ...optionalParams].join(' ');
        if (isDEVSentryENV()) {
            console.log(completeLog);
        }

        if (isElectron()) {
            ElectronService.logToDisk(completeLog);
        } else {
            saveLogLine({
                timestamp: Date.now(),
                logLine: completeLog,
            });
        }
    } catch (e) {
        if (e.name === 'QuotaExceededError') {
            deleteLogs();
            addLogLine('logs cleared');
        }
        logError(e, 'failed to addLogLine', undefined, true);
        // ignore
    }
}

export const addLocalLog = (getLog: () => string) => {
    if (isDEVSentryENV()) {
        console.log(getLog());
    }
};

export function getDebugLogs() {
    return combineLogLines(getLogs());
}

export function getFileNameSize(file: File | ElectronFile) {
    return `${file.name}_${convertBytesToHumanReadable(file.size)}`;
}

export const clearLogsIfLocalStorageLimitExceeded = () => {
    try {
        const logs = getDebugLogs();
        const logSize = getStringSize(logs);
        if (logSize > MAX_LOG_SIZE) {
            deleteLogs();
            addLogLine('Logs cleared due to size limit exceeded');
        } else {
            try {
                addLogLine(`app started`);
            } catch (e) {
                deleteLogs();
            }
        }
        addLogLine(`logs size: ${convertBytesToHumanReadable(logSize)}`);
    } catch (e) {
        logError(e, 'failed to clearLogsIfLocalStorageLimitExceeded');
    }
};

function saveLogLine(log: Log) {
    const logs = getLogs();
    if (logs.length > MAX_LOG_LINES) {
        logs.slice(logs.length - MAX_LOG_LINES);
    }
    logs.push(log);
    setLogs(logs);
}

function getLogs(): Log[] {
    return getData(LS_KEYS.LOGS)?.logs ?? [];
}

function setLogs(logs: Log[]) {
    setData(LS_KEYS.LOGS, { logs });
}

function deleteLogs() {
    removeData(LS_KEYS.LOGS);
}

function getStringSize(str: string) {
    return new Blob([str]).size;
}

function formatLog(log: Log) {
    return `[${formatDateTimeShort(log.timestamp)}] ${log.logLine}`;
}

function combineLogLines(logs: Log[]) {
    return logs.map(formatLog).join('\n');
}
