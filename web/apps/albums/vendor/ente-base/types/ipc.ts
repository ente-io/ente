export interface Electron {
    openDirectory: (dirPath: string) => Promise<void>;
}

export type ZipItem = [zipPath: string, entryName: string];
