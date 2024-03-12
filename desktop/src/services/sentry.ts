import { isDev } from "../utils/common";
import { logToDisk } from "./logging";

/** Deprecated, but no alternative yet */
export function logErrorSentry(
    error: any,
    msg: string,
    info?: Record<string, unknown>,
) {
    logToDisk(
        `error: ${error?.name} ${error?.message} ${
            error?.stack
        } msg: ${msg} info: ${JSON.stringify(info)}`,
    );
    if (isDev) {
        console.log(error, { msg, info });
    }
}
