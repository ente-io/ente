import ElectronAPIs from "@/next/electron";
import { inWorker, isDevBuild } from "@/next/env";
import log from "@/next/log";
import { logWeb } from "@/next/web";
import { logError } from "@ente/shared/sentry";
import isElectron from "is-electron";
import { workerBridge } from "../worker/worker-bridge";

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

export const addLocalLog = log.debug;
