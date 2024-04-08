import { ApiError } from "@ente/shared/error";
import { addLogLine } from "@ente/shared/logging";

/** Deprecated: Use `logError` from `@/utils/logging` */
export const logError = async (
    error: any,
    msg: string,
    info?: Record<string, unknown>,
    skipAddLogLine = false,
) => {
    if (skipAddLogLine) return;

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
};
