declare module "@tauri-apps/api/tauri" {
    export function invoke<T = unknown>(
        command: string,
        args?: Record<string, unknown>,
    ): Promise<T>;
}
