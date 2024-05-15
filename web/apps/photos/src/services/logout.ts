import log from "@/next/log";
import { accountLogout } from "@ente/accounts/services/logout";
import { Events, eventBus } from "@ente/shared/events";

/**
 * Logout sequence for the photos app.
 *
 * This function is guaranteed not to throw any errors.
 *
 * See: [Note: Do not throw during logout].
 */
export const photosLogout = async () => {
    await accountLogout();

    const electron = globalThis.electron;
    if (electron) {
        try {
            await electron.watch.reset();
        } catch (e) {
            log.error("Ignoring error when resetting native folder watches", e);
        }
        try {
            await electron.clearConvertToMP4Results();
        } catch (e) {
            log.error("Ignoring error when clearing convert-to-mp4 results", e);
        }
        try {
            await electron.clearStores();
        } catch (e) {
            log.error("Ignoring error when clearing native stores", e);
        }
    }
    try {
        eventBus.emit(Events.LOGOUT);
    } catch (e) {
        log.error("Ignoring error in event-bus logout handlers", e);
    }
};
