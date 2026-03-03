declare module "@tauri-apps/api/path" {
    export function appDataDir(): Promise<string>;
    export function join(...paths: string[]): Promise<string>;
    export function dirname(path: string): Promise<string>;
}

declare module "@tauri-apps/plugin-fs" {
    export function mkdir(
        path: string,
        options?: { recursive?: boolean },
    ): Promise<void>;
    export function writeFile(path: string, data: Uint8Array): Promise<void>;
    export function readFile(path: string): Promise<Uint8Array>;
    export function exists(path: string): Promise<boolean>;
    export function remove(path: string): Promise<void>;
    export function rename(oldPath: string, newPath: string): Promise<void>;
}

declare module "@tauri-apps/plugin-dialog" {
    export function open(
        options?: Record<string, unknown>,
    ): Promise<string | string[] | null>;
    export function save(options?: Record<string, unknown>): Promise<string | null>;
}
