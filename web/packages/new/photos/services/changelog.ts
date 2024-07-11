import { ensureElectron } from "@/next/electron";

/**
 * The current changelog version.
 *
 * [Note: Conditions for showing "What's new"]
 *
 * We maintain a "changelog version". This version is an incrementing positive
 * integer, we increment it whenever we want to show this dialog again. Usually
 * we'd do this for each app update, but not necessarily.
 *
 * The "What's new" dialog is shown when either we do not have a previously
 * saved changelog version, or if the saved changelog version is less than the
 * current {@link changelogVersion}.
 *
 * The shown changelog version is persisted on the Node.js layer since there we
 * can store it in the user preferences store, which is not cleared on logout.
 *
 * On app start, the Node.js layer waits for the {@link onShowWhatsNew} callback
 * to get attached. When a callback is attached, it checks the above conditions
 * and if they are satisfied, it invokes the callback. The callback should
 * return the current {@link changelogVersion} to allow the Node.js layer to
 * update the persisted state.
 */
const changelogVersion = 1;

/**
 * Return true if we should show the {@link WhatsNew} dialog.
 */
export const shouldShowWhatsNew = async () => {
    const electron = globalThis.electron;
    if (!electron) return false;
    const lastShownVersion = (await electron.lastShownChangelogVersion()) ?? 0;
    return lastShownVersion < changelogVersion;
};

export const didShowWhatsNew = async () =>
    // We should only have been called if we're in electron.
    ensureElectron().setLastShownChangelogVersion(changelogVersion);
