import { accountLogout } from "ente-accounts/services/logout";
import log from "ente-base/log";
import { isTauriRuntime } from "services/tauri-runtime";

/**
 * Logout sequence for the Ensu app.
 *
 * This function is guaranteed not to throw any errors.
 */
export const ensuLogout = async () => {
    const ignoreError = (label: string, e: unknown) =>
        log.error(`Ignoring error during logout (${label})`, e);

    await accountLogout();

    if (isTauriRuntime()) {
        try {
            const { invoke } = await import("@tauri-apps/api/core");
            await invoke("chat_db_reset");
        } catch (e) {
            ignoreError("Tauri chat DB", e);
        }
    }

    window.location.replace("/");
};
