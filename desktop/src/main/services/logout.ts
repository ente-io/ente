import type { FSWatcher } from "chokidar";
import log from "../log";
import { clearConvertToMP4Results } from "../stream";
import { clearStores } from "./store";
import { watchReset } from "./watch";

/**
 * Perform the native side logout sequence.
 *
 * This function is guaranteed not to throw any errors.
 *
 * See: [Note: Do not throw during logout].
 */
export const logout = (watcher: FSWatcher) => {
    try {
        watchReset(watcher);
    } catch (e) {
        log.error("Ignoring error during logout (FS watch)", e);
    }
    try {
        clearConvertToMP4Results();
    } catch (e) {
        log.error("Ignoring error during logout (convert-to-mp4)", e);
    }
    try {
        clearStores();
    } catch (e) {
        log.error("Ignoring error during logout (native stores)", e);
    }
};
