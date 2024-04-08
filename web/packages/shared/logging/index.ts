import { inWorker, isDevBuild } from "@/next/env";
import { logError } from "@ente/shared/sentry";
import isElectron from "is-electron";
import ElectronAPIs from "@/next/electron";
import { workerBridge } from "../worker/worker-bridge";
import { formatLog, logWeb } from "./web";

export const MAX_LOG_SIZE = 5 * 1024 * 1024; // 5MB
export const MAX_LOG_LINES = 1000;

export const logToDisk = (message: string) => {
    if (isElectron()) {
        ElectronAPIs.logToDisk(message);
    } else {
        logWeb(message);
    }
};

export function addLogLine(
    log: string | number | boolean,
    ...optionalParams: (string | number | boolean)[]
) {
    try {
        const completeLog = [log, ...optionalParams].join(" ");
        if (isDevBuild) {
            console.log(completeLog);
        }
        if (inWorker()) {
            workerBridge
                .logToDisk(completeLog)
                .catch((e) =>
                    console.error(
                        "Failed to log a message from worker",
                        e,
                        "\nThe message was",
                        completeLog,
                    ),
                );
        } else {
            logToDisk(completeLog);
        }
    } catch (e) {
        logError(e, "failed to addLogLine", undefined, true);
        // ignore
    }
}

export const addLocalLog = (getLog: () => string) => {
    if (isDevBuild) {
        console.log(
            formatLog({
                logLine: getLog(),
                timestamp: Date.now(),
            }),
        );
    }
};
