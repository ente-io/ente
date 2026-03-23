const isTauriRuntime = () =>
    typeof window !== "undefined" &&
    ("__TAURI__" in window || "__TAURI_IPC__" in window);

const tauriInvoke = async <T>(
    command: string,
    args?: Record<string, unknown>,
): Promise<T> => {
    const { invoke } = await import("@tauri-apps/api/tauri");
    return invoke<T>(command, args);
};

export const secureStorageGet = async (key: string) => {
    if (!isTauriRuntime()) return undefined;
    return tauriInvoke<string | null>("secure_storage_get", { key }).then(
        (value) => value ?? undefined,
    );
};

export const secureStorageSet = async (key: string, value: string) => {
    if (!isTauriRuntime()) return;
    await tauriInvoke("secure_storage_set", { key, value });
};

export const secureStorageDelete = async (key: string) => {
    if (!isTauriRuntime()) return;
    await tauriInvoke("secure_storage_delete", { key });
};

export const isTauriAppRuntime = isTauriRuntime;
