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

type FileMapping = {
    path: string;
    id: number;
};

interface Mapping {
    rootFolderName: string;
    uploadStrategy: number;
    folderPath: string;
    files: FileMapping[];
}

export interface WatchStoreType {
    mappings: Mapping[];
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
