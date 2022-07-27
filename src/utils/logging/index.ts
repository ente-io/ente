import { ElectronFile } from 'types/upload';
import { convertBytesToHumanReadable } from 'utils/billing';
import { formatDateTime } from 'utils/file';
import { saveLogLine, getLogs } from 'utils/storage';

export function addLogLine(log: string) {
    saveLogLine({
        timestamp: Date.now(),
        logLine: log,
    });
}

export function getDebugLogs() {
    return getLogs().map(
        (log) => `[${formatDateTime(log.timestamp)}] ${log.logLine}`
    );
}

export function getFileNameSize(file: File | ElectronFile) {
    return `${file.name}_${convertBytesToHumanReadable(file.size)}`;
}
