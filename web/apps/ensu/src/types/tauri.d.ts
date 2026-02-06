declare module "@tauri-apps/api/path" {
    export function appDataDir(): Promise<string>;
    export function join(...paths: string[]): Promise<string>;
    export function dirname(path: string): Promise<string>;
}

declare module "@tauri-apps/api/fs" {
    export function createDir(
        path: string,
        options?: { recursive?: boolean },
    ): Promise<void>;
    export function writeBinaryFile(options: {
        path: string;
        contents: Uint8Array;
    }): Promise<void>;
    export function readBinaryFile(path: string): Promise<Uint8Array>;
    export function exists(path: string): Promise<boolean>;
    export function removeFile(path: string): Promise<void>;
    export function renameFile(oldPath: string, newPath: string): Promise<void>;
}
