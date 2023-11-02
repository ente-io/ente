export interface AppUpdateInfo {
    autoUpdatable: boolean;
    version: string;
}

export interface ElectronAPIsType {
    exists: (path: string) => boolean;
    checkExistsAndCreateDir: (dirPath: string) => Promise<void>;
    saveStreamToDisk: (
        path: string,
        fileStream: ReadableStream<any>
    ) => Promise<void>;
    saveFileToDisk: (path: string, file: any) => Promise<void>;
    selectDirectory: () => Promise<string>;
    sendNotification: (content: string) => void;
    readTextFile: (path: string) => Promise<string>;
    setToUploadFiles: (type: string, filePaths: string[]) => void;
    setToUploadCollection: (collectionName: string) => void;
    addWatchMapping: (
        collectionName: string,
        folderPath: string,
        uploadStrategy: number
    ) => Promise<void>;
    removeWatchMapping: (folderPath: string) => Promise<void>;
    isFolder: (dirPath: string) => Promise<boolean>;
    clearElectronStore: () => void;
    setEncryptionKey: (encryptionKey: string) => Promise<void>;
    getEncryptionKey: () => Promise<string>;
    deleteDiskCache: (cacheName: string) => Promise<boolean>;
    logToDisk: (msg: string) => void;
    convertToJPEG: (
        fileData: Uint8Array,
        filename: string
    ) => Promise<Uint8Array>;
    openLogDirectory: () => void;
    registerUpdateEventListener: (
        showUpdateDialog: (updateInfo: AppUpdateInfo) => void
    ) => void;
    updateAndRestart: () => void;
    skipAppUpdate: (version: string) => void;
    getSentryUserID: () => Promise<string>;
    getAppVersion: () => Promise<string>;
    muteUpdateNotification: (version: string) => void;
    logRendererProcessMemoryUsage: (message: string) => Promise<void>;
    registerForegroundEventListener: (onForeground: () => void) => void;
    openDirectory: (dirPath: string) => Promise<void>;
    moveFile: (oldPath: string, newPath: string) => Promise<void>;
    deleteFolder: (path: string) => Promise<void>;
    deleteFile: (path: string) => void;
    rename: (oldPath: string, newPath: string) => Promise<void>;
    updateOptOutOfCrashReports: (optOut: boolean) => Promise<void>;
}
