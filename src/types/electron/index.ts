import { ElectronFile } from 'types/upload';

export interface ElectronAPIs {
    exists: (path: string) => boolean;
    checkExistsAndCreateCollectionDir: (dirPath: string) => Promise<void>;
    checkExistsAndRename: (
        oldDirPath: string,
        newDirPath: string
    ) => Promise<void>;
    saveStreamToDisk: (path: string, fileStream: ReadableStream<any>) => void;
    saveFileToDisk: (path: string, file: any) => Promise<void>;
    selectRootDirectory: () => Promise<any>;
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
    clearElectronStore: () => void;
    setEncryptionKey: (encryptionKey: string) => Promise<void>;
    getEncryptionKey: () => Promise<any>;
    openDiskCache: (cacheName: string) => Promise<Cache>;
    deleteDiskCache: (cacheName: string) => Promise<boolean>;
}
