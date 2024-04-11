import { isDevBuild } from "@/next/env";
import log from "@/next/log";

/**
 * Log a standard startup banner.
 *
 * This helps us identify app starts and other environment details in the logs.
 *
 * @param appId An identifier of the app that is starting.
 * @param userId The uid for the currently logged in user, if any.
 */
export const logStartupBanner = (appId: string, userId?: number) => {
    // TODO (MR): Remove the need to lowercase it, change the enum itself.
    const appIdL = appId.toLowerCase();
    const sha = process.env.GIT_SHA;
    const buildId = isDevBuild ? "dev " : sha ? `git ${sha} ` : "";

    log.info(`Starting ente-${appIdL}-web ${buildId}uid ${userId ?? 0}`);
};

/**
 * Attach handlers to log any unhandled exceptions and promise rejections.
 *
 * @param attach If true, attach handlers, and if false, remove them. This
 * allows us to use this in a React hook that cleans up after itself.
 */
export const logUnhandledErrorsAndRejections = (attach: boolean) => {
    const handleError = (event: ErrorEvent) => {
        log.error("Unhandled error", event.error);
    };

    const handleUnhandledRejection = (event: PromiseRejectionEvent) => {
        log.error("Unhandled promise rejection", event.reason);
    };

    if (attach) {
        window.addEventListener("error", handleError);
        window.addEventListener("unhandledrejection", handleUnhandledRejection);
    } else {
        window.removeEventListener("error", handleError);
        window.removeEventListener(
            "unhandledrejection",
            handleUnhandledRejection,
        );
    }
};

interface LogEntry {
    timestamp: number;
    logLine: string;
}

const lsKey = "logs";

/**
 * Record {@link message} in a persistent log storage.
 *
 * These strings, alongwith associated timestamps, get added to a small ring
 * buffer, whose contents can be later be retrieved by using {@link savedLogs}.
 *
 * This ring buffer is persisted in the browser's local storage.
 */
export const logToDisk = (message: string) => {
    const maxCount = 1000;
    const log: LogEntry = { logLine: message, timestamp: Date.now() };
    try {
        const logs = logEntries();
        if (logs.length > maxCount) {
            logs.slice(logs.length - maxCount);
        }
        logs.push(log);
        localStorage.setItem(lsKey, JSON.stringify({ logs }));
    } catch (e) {
        console.error("Failed to persist log", e);
        if (e instanceof Error && e.name === "QuotaExceededError") {
            localStorage.removeItem(lsKey);
        }
    }
};

const logEntries = (): unknown[] => {
    const s = localStorage.getItem("logs");
    if (!s) return [];
    const o: unknown = JSON.parse(s);
    if (!(o && typeof o == "object" && "logs" in o && Array.isArray(o.logs))) {
        console.error("Unexpected log entries obtained from local storage", o);
        return [];
    }
    return o.logs;
};

/**
 * Return a string containing all recently saved log messages.
 *
 * @see {@link persistLog}.
 */
export const savedLogs = () => logEntries().map(formatEntry).join("\n");

const formatEntry = (e: unknown) => {
    if (e && typeof e == "object" && "timestamp" in e && "logLine" in e) {
        const timestamp = e.timestamp;
        const logLine = e.logLine;
        if (typeof timestamp == "number" && typeof logLine == "string") {
            return `[${new Date(timestamp).toISOString()}] ${logLine}`;
        }
    }
    return String(e);
};
