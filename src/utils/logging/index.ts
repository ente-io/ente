import { ElectronFile } from 'types/upload';
import { convertBytesToHumanReadable } from 'utils/file/size';
import { formatDateTime } from 'utils/time';
import { saveLogLine, getLogs } from 'utils/storage';

// commented out need fixing
export function pipeConsoleLogsToDebugLogs() {
    return;
    const oldLog = console.log;
    console.log = function (...args) {
        addLogLine(args.map((x) => JSON.stringify(x)).join(' '));
        oldLog.apply(console, args);
    };
}

export function addLogLine(log: string) {
    if (!process.env.NEXT_PUBLIC_SENTRY_ENV) {
        console.log(log);
    }
    saveLogLine({
        timestamp: Date.now(),
        logLine: log,
    });
}

export const addLocalLog = (getLog: () => string) => {
    if (!process.env.NEXT_PUBLIC_SENTRY_ENV) {
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
