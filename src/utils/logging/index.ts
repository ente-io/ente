import { ElectronFile } from 'types/upload';
import { convertBytesToHumanReadable } from 'utils/file/size';
import { formatDateTime } from 'utils/time';
import { saveLogLine, getLogs } from 'utils/storage';

export function pipeConsoleLogsToDebugLogs() {
    const oldLog = console.log;
    console.log = function (...args) {
        addLogLine(args.map((x) => JSON.stringify(x)).join(' '));
        oldLog.apply(console, args);
    };
}

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
