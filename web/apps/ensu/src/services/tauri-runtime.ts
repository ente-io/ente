type TauriRuntimeWindow = Window & { isTauri?: unknown };

export const isTauriRuntime = () => {
    if (typeof window === "undefined") return false;

    const tauriWindow = window as TauriRuntimeWindow;
    return (
        tauriWindow.isTauri === true ||
        "__TAURI__" in tauriWindow ||
        "__TAURI_IPC__" in tauriWindow ||
        "__TAURI_INTERNALS__" in tauriWindow ||
        "__TAURI_METADATA__" in tauriWindow
    );
};
