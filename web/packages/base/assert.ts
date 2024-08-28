import { isDevBuild } from "./env";
import log from "./log";

/**
 * If running in a dev build, throw an exception with the given message.
 * Otherwise log it as a warning.
 */
export const assertionFailed = (message: string) => {
    if (isDevBuild) throw new Error(message);
    log.warn(message);
};
