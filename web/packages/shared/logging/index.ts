import { inWorker, isDevBuild } from "@/next/env";
import log, { logToDisk } from "@/next/log";
import { logError } from "@ente/shared/sentry";
import { workerBridge } from "../worker/worker-bridge";

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
