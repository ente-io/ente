import type { FSWatcher } from "chokidar";
import log from "../log";
import { clearConvertToMP4Results } from "../stream";
import { clearStores } from "./store";
import { watchReset } from "./watch";
import { clearOpenZipCache } from "./zip";

/**
 * Perform the native side logout sequence.
 *
 * This function is guaranteed not to throw any errors.
 *
 * See: [Note: Do not throw during logout].
 */
export const logout = (watcher: FSWatcher) => {
    const ignoreError = (label: string, e: unknown) =>
        log.error(`Ignoring error during logout (${label})`, e);

    try {
        watchReset(watcher);
    } catch (e) {
        ignoreError("FS watch", e);
    }
    try {
        clearConvertToMP4Results();
    } catch (e) {
        ignoreError("convert-to-mp4", e);
    }
    try {
        clearStores();
    } catch (e) {
        ignoreError("native stores", e);
    }
    try {
        clearOpenZipCache();
    } catch (e) {
        ignoreError("zip cache", e);
    }
};
