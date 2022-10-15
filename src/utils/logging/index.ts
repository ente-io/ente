import { ElectronFile } from 'types/upload';
import { convertBytesToHumanReadable } from 'utils/file/size';
import { formatDateTime } from 'utils/time';
import { saveLogLine, getLogs } from 'utils/storage';
import { isDEVSentryENV } from 'constants/sentry';
import isElectron from 'is-electron';
import ElectronService from 'services/electron/common';

export function addLogLine(log: string) {
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
}

export const addLocalLog = (getLog: () => string) => {
    if (isDEVSentryENV()) {
        console.log(getLog());
    }
};

export function getDebugLogs() {
    return getLogs().map(
        (log) => `[${formatDateTime(log.timestamp)}] ${log.logLine}`
    );
}

export function getFileNameSize(file: File | ElectronFile) {
    return `${file.name}_${convertBytesToHumanReadable(file.size)}`;
}
