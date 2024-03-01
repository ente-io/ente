import { ApiError, errorWithContext } from "@ente/shared/error";
import { addLocalLog, addLogLine } from "@ente/shared/logging";
import {
    getSentryUserID,
    isErrorUnnecessaryForSentry,
} from "@ente/shared/sentry/utils";
import InMemoryStore, { MS_KEYS } from "@ente/shared/storage/InMemoryStore";
import { getHasOptedOutOfCrashReports } from "@ente/shared/storage/localStorage/helpers";
import * as Sentry from "@sentry/nextjs";

export const logError = async (
    error: any,
    msg: string,
    info?: Record<string, unknown>,
    skipAddLogLine = false,
) => {
    const err = errorWithContext(error, msg);
    if (!skipAddLogLine) {
        if (error instanceof ApiError) {
            addLogLine(`error: ${error?.name} ${error?.message} 
            msg: ${msg} errorCode: ${JSON.stringify(error?.errCode)}
            httpStatusCode: ${JSON.stringify(error?.httpStatusCode)} ${
                info ? `info: ${JSON.stringify(info)}` : ""
            }
            ${error?.stack}`);
        } else {
            addLogLine(
                `error: ${error?.name} ${error?.message} 
                msg: ${msg} ${info ? `info: ${JSON.stringify(info)}` : ""}
                ${error?.stack}`,
            );
        }
    }
    if (!InMemoryStore.has(MS_KEYS.OPT_OUT_OF_CRASH_REPORTS)) {
        const optedOutOfCrashReports = getHasOptedOutOfCrashReports();
        InMemoryStore.set(
            MS_KEYS.OPT_OUT_OF_CRASH_REPORTS,
            optedOutOfCrashReports,
        );
    }
    if (InMemoryStore.get(MS_KEYS.OPT_OUT_OF_CRASH_REPORTS)) {
        addLocalLog(() => `skipping sentry error: ${error?.name}`);
        return;
    }
    if (isErrorUnnecessaryForSentry(error)) {
        return;
    }

    Sentry.captureException(err, {
        level: "info",
        user: { id: await getSentryUserID() },
        contexts: {
            ...(info && {
                info: info,
            }),
            rootCause: { message: error?.message, completeError: error },
        },
    });
};
