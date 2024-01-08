import { LimitedCache } from '@ente/shared/storage/cacheStorage/types';
import { ElectronFile } from '@ente/shared/upload/types';
import { WatchMapping } from '@ente/shared/watchFolder/types';

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
    showUploadFilesDialog: () => Promise<ElectronFile[]>;
    showUploadDirsDialog: () => Promise<ElectronFile[]>;
    getPendingUploads: () => Promise<{
        files: ElectronFile[];
        collectionName: string;
        type: string;
    }>;
    setToUploadFiles: (type: string, filePaths: string[]) => void;
    showUploadZipDialog: () => Promise<{
        zipPaths: string[];
        files: ElectronFile[];
    }>;
    getElectronFilesFromGoogleZip: (
        filePath: string
    ) => Promise<ElectronFile[]>;
    setToUploadCollection: (collectionName: string) => void;
    getDirFiles: (dirPath: string) => Promise<ElectronFile[]>;
    getWatchMappings: () => WatchMapping[];
    updateWatchMappingSyncedFiles: (
        folderPath: string,
        files: WatchMapping['syncedFiles']
    ) => void;
    updateWatchMappingIgnoredFiles: (
        folderPath: string,
        files: WatchMapping['ignoredFiles']
    ) => void;
    addWatchMapping: (
        collectionName: string,
        folderPath: string,
        uploadStrategy: number
    ) => Promise<void>;
    removeWatchMapping: (folderPath: string) => Promise<void>;
    registerWatcherFunctions: (
        addFile: (file: ElectronFile) => Promise<void>,
        removeFile: (path: string) => Promise<void>,
        removeFolder: (folderPath: string) => Promise<void>
    ) => void;
    isFolder: (dirPath: string) => Promise<boolean>;
    clearElectronStore: () => void;
    setEncryptionKey: (encryptionKey: string) => Promise<void>;
    getEncryptionKey: () => Promise<string>;
    openDiskCache: (
        cacheName: string,
        cacheLimitInBytes?: number
    ) => Promise<LimitedCache>;
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
    runFFmpegCmd: (
        cmd: string[],
        inputFile: File | ElectronFile,
        outputFileName: string,
        dontTimeout?: boolean
    ) => Promise<File>;
    muteUpdateNotification: (version: string) => void;
    generateImageThumbnail: (
        inputFile: File | ElectronFile,
        maxDimension: number,
        maxSize: number
    ) => Promise<Uint8Array>;
    logRendererProcessMemoryUsage: (message: string) => Promise<void>;
    registerForegroundEventListener: (onForeground: () => void) => void;
    openDirectory: (dirPath: string) => Promise<void>;
    moveFile: (oldPath: string, newPath: string) => Promise<void>;
    deleteFolder: (path: string) => Promise<void>;
    deleteFile: (path: string) => void;
    rename: (oldPath: string, newPath: string) => Promise<void>;
    updateOptOutOfCrashReports: (optOut: boolean) => Promise<void>;
    computeImageEmbedding: (imageData: Uint8Array) => Promise<Float32Array>;
    computeTextEmbedding: (text: string) => Promise<Float32Array>;
    getPlatform: () => Promise<'mac' | 'windows' | 'linux'>;
    setCustomCacheDirectory: (directory: string) => Promise<void>;
    getCacheDirectory: () => Promise<string>;
}
