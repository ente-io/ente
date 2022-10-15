import { ElectronFile } from 'types/upload';
import { WatchMapping } from 'types/watchFolder';

export interface ElectronAPIs {
    exists: (path: string) => boolean;
    checkExistsAndCreateCollectionDir: (dirPath: string) => Promise<void>;
    checkExistsAndRename: (
        oldDirPath: string,
        newDirPath: string
    ) => Promise<void>;
    saveStreamToDisk: (path: string, fileStream: ReadableStream<any>) => void;
    saveFileToDisk: (path: string, file: any) => Promise<void>;
    selectRootDirectory: () => Promise<string>;
    sendNotification: (content: string) => void;
    showOnTray: (content?: any) => void;
    registerResumeExportListener: (resumeExport: () => void) => void;
    registerStopExportListener: (abortExport: () => void) => void;
    registerPauseExportListener: (pauseExport: () => void) => void;
    registerRetryFailedExportListener: (retryFailedExport: () => void) => void;
    getExportRecord: (filePath: string) => Promise<string>;
    setExportRecord: (filePath: string, data: string) => Promise<void>;
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
    openDiskCache: (cacheName: string) => Promise<Cache>;
    deleteDiskCache: (cacheName: string) => Promise<boolean>;
    logToDisk: (msg: string) => void;
    openLogDirectory: () => void;
}
