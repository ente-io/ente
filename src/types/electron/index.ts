import { WatchService } from 'services/watchService';
import { ElectronFile } from 'types/upload';
import { WatchMapping } from 'types/watch';

export interface ElectronAPIsInterface {
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
    reloadWindow: () => void;
    registerResumeExportListener: (resumeExport: () => void) => void;
    registerStopExportListener: (abortExport: () => void) => void;
    registerPauseExportListener: (pauseExport: () => void) => void;
    registerRetryFailedExportListener: (retryFailedExport: () => void) => void;
    getExportRecord: (filePath: string) => Promise<string>;
    setExportRecord: (filePath: string, data: string) => Promise<void>;
    getElectronFile: (filePath: string) => Promise<ElectronFile>;
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
    getAllFilesFromDir: (dirPath: string) => Promise<ElectronFile[]>;
    getWatchMappings: () => WatchMapping[];
    setWatchMappings: (watchMappings: WatchMapping[]) => void;
    addWatchMapping: (
        collectionName: string,
        folderPath: string
    ) => Promise<void>;
    removeWatchMapping: (collectionName: string) => Promise<void>;
    registerWatcherFunctions: (
        WatchServiceInstance: WatchService,
        addFile: (
            WatchServiceInstance: WatchService,
            file: ElectronFile
        ) => Promise<void>,
        removeFile: (
            WatchServiceInstance: WatchService,
            path: string
        ) => Promise<void>,
        removeFolder: (
            WatchServiceInstance: WatchService,
            folderPath: string
        ) => Promise<void>
    ) => void;
    doesFolderExists: (dirPath: string) => Promise<boolean>;
}
