import log from "electron-log";

export function setupLogging(isDev?: boolean) {
    log.transports.file.fileName = "ente.log";
    log.transports.file.maxSize = 50 * 1024 * 1024; // 50MB;
    if (!isDev) {
        log.transports.console.level = false;
    }
    log.transports.file.format =
        "[{y}-{m}-{d}T{h}:{i}:{s}{z}] [{level}]{scope} {text}";
}

export function convertBytesToHumanReadable(
    bytes: number,
    precision = 2,
): string {
    if (bytes === 0 || isNaN(bytes)) {
        return "0 MB";
    }

    const i = Math.floor(Math.log(bytes) / Math.log(1024));
    const sizes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    return (bytes / Math.pow(1024, i)).toFixed(precision) + " " + sizes[i];
}
