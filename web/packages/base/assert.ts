import { isDevBuild } from "./env";
import log from "./log";

/**
 * If running in a dev build, throw an exception with the given message.
 * Otherwise log it as a warning.
 *
 * @param message An optional message to use for the failure. If not provided,
 * then a generic one is used.
 */
export const assertionFailed = (message?: string) => {
    message = message ?? "Assertion failed";
    if (isDevBuild) throw new Error(message);
    log.warn(message);
};
