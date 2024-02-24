import { isDevBuild } from "@/utils/env";
import { logError } from "@ente/shared/sentry";
import {
    getData,
    LS_KEYS,
    removeData,
    setData,
} from "@ente/shared/storage/localStorage";
import { addLogLine } from ".";
import { getSentryUserID } from "../sentry/utils";
import { formatDateTimeShort } from "../time/format";
import { ElectronFile } from "../upload/types";
import type { User } from "../user/types";
import { convertBytesToHumanReadable } from "../utils/size";

export const MAX_LOG_SIZE = 5 * 1024 * 1024; // 5MB
export const MAX_LOG_LINES = 1000;

export interface Log {
    timestamp: number;
    logLine: string;
}

export function logWeb(logLine: string) {
    try {
        const log: Log = { logLine, timestamp: Date.now() };
        const logs = getLogs();
        if (logs.length > MAX_LOG_LINES) {
            logs.slice(logs.length - MAX_LOG_LINES);
        }
        logs.push(log);
        setLogs(logs);
    } catch (e) {
        if (e.name === "QuotaExceededError") {
            deleteLogs();
            logWeb("logs cleared");
        }
    }
}

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
            logWeb("Logs cleared due to size limit exceeded");
        } else {
            try {
                logWeb(`app started`);
            } catch (e) {
                deleteLogs();
            }
        }
        logWeb(`logs size: ${convertBytesToHumanReadable(logSize)}`);
    } catch (e) {
        logError(
            e,
            "failed to clearLogsIfLocalStorageLimitExceeded",
            undefined,
            true,
        );
    }
};

export const logStartupMessage = async (appId: string) => {
    // TODO (MR): Remove the need to lowercase it, change the enum itself.
    const appIdL = appId.toLowerCase();
    const userID = (getData(LS_KEYS.USER) as User)?.id;
    const sentryID = await getSentryUserID();
    const buildId = isDevBuild ? "dev" : `git ${process.env.GIT_SHA}`;

    addLogLine(`ente-${appIdL}-web ${buildId} uid ${userID} sid ${sentryID}`);
};

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

export function formatLog(log: Log) {
    return `[${formatDateTimeShort(log.timestamp)}] ${log.logLine}`;
}

function combineLogLines(logs: Log[]) {
    return logs.map(formatLog).join("\n");
}
