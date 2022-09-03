export interface ElectronFile {
    name: string;
    path: string;
    size: number;
    lastModified: number;
    stream: () => Promise<ReadableStream<Uint8Array>>;
    blob: () => Promise<Blob>;
    arrayBuffer: () => Promise<Uint8Array>;
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

export enum FILE_PATH_TYPE {
    FILES = 'files',
    ZIPS = 'zips',
}

export const FILE_PATH_KEYS: {
    [k in FILE_PATH_TYPE]: keyof UploadStoreType;
} = {
    [FILE_PATH_TYPE.ZIPS]: 'zipPaths',
    [FILE_PATH_TYPE.FILES]: 'filePaths',
};

export interface SafeStorageStoreType {
    encryptionKey: string;
}

export interface UserPreferencesType {
    hideDockIcon: boolean;
}
