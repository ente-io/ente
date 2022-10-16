import { ElectronFile } from 'types/upload';
import { convertBytesToHumanReadable } from 'utils/file/size';
import { formatDateTime } from 'utils/time';
import { Log } from 'utils/storage';
import { isDEVSentryENV } from 'constants/sentry';
import isElectron from 'is-electron';
import ElectronService from 'services/electron/common';
import { logError } from 'utils/sentry';
import { MAX_LOG_SIZE } from 'constants/logging';
import {
    getData,
    LS_KEYS,
    removeData,
    setData,
} from 'utils/storage/localStorage';

export function addLogLine(log: string) {
    try {
        if (isDEVSentryENV()) {
            console.log(log);
        }
        if (isElectron()) {
            ElectronService.logToDisk(log);
        } else {
            saveLogLine({
                timestamp: Date.now(),
                logLine: log,
            });
        }
    } catch (e) {
        logError(e, 'failed to addLogLine');
        // ignore
    }
}

export const addLocalLog = (getLog: () => string) => {
    if (isDEVSentryENV()) {
        console.log(getLog());
    }
};

export function getDebugLogs() {
    return getLogs().map(formatLog).join('\n');
}

export function getFileNameSize(file: File | ElectronFile) {
    return `${file.name}_${convertBytesToHumanReadable(file.size)}`;
}

export function saveLogLine(log: Log) {
    try {
        const logs = getLogs();
        let logSize = getStringSize(logs.map(formatLog).join('\n'));
        while (logSize > MAX_LOG_SIZE) {
            logs.shift();
            logSize = getStringSize(logs.map(formatLog).join('\n'));
        }
        setLogs([...logs, log]);
    } catch (e) {
        logError(e, 'failed to save log line');
        // don't throw
    }
}

function getStringSize(str: string) {
    return new Blob([str]).size;
}
function formatLog(log: Log) {
    return `[${formatDateTime(log.timestamp)}] ${log.logLine}`;
}

export const clearLogsIfLocalStorageLimitExceeded = () => {
    const logs = getDebugLogs();
    const logStringSize = new Blob([logs]).size;
    if (logStringSize > MAX_LOG_SIZE) {
        deleteLogs();
        addLogLine('Logs cleared due to size limit exceeded');
    } else {
        try {
            addLogLine(`app started`);
        } catch (e) {
            deleteLogs();
            logError(e, 'failed to log test log');
        }
    }
    addLogLine(`logs size: ${convertBytesToHumanReadable(logStringSize)}`);
};

function getLogs(): Log[] {
    return getData(LS_KEYS.LOGS)?.logs ?? [];
}

function setLogs(logs: Log[]) {
    setData(LS_KEYS.LOGS, { logs });
}

export function deleteLogs() {
    removeData(LS_KEYS.LOGS);
}
