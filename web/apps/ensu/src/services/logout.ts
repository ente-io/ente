import { invoke } from "@tauri-apps/api/tauri";
import { accountLogout } from "ente-accounts/services/logout";
import log from "ente-base/log";

const isTauriRuntime = () =>
    typeof window !== "undefined" &&
    ("__TAURI__" in window || "__TAURI_IPC__" in window);

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
            await invoke("chat_db_reset");
        } catch (e) {
            ignoreError("Tauri chat DB", e);
        }
    }

    window.location.replace("/");
};
