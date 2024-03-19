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
