import { FILE_PATH_TYPE } from "./ipc";

export interface AutoLauncherClient {
    isEnabled: () => Promise<boolean>;
    toggleAutoLaunch: () => Promise<void>;
    wasAutoLaunched: () => Promise<boolean>;
}

export interface UploadStoreType {
    filePaths: string[];
    zipPaths: string[];
    collectionName: string;
}

export interface KeysStoreType {
    AnonymizeUserID: {
        id: string;
    };
}

export const FILE_PATH_KEYS: {
    [k in FILE_PATH_TYPE]: keyof UploadStoreType;
} = {
    [FILE_PATH_TYPE.ZIPS]: "zipPaths",
    [FILE_PATH_TYPE.FILES]: "filePaths",
};

export interface SafeStorageStoreType {
    encryptionKey: string;
}

export interface UserPreferencesType {
    hideDockIcon: boolean;
    skipAppVersion: string;
    muteUpdateNotificationVersion: string;
}
