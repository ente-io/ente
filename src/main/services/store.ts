import Store, { Schema } from 'electron-store';
import { KeysStoreType, SafeStorageStoreType, UploadStoreType } from '../types';

export const uploadStoreSchema: Schema<UploadStoreType> = {
    filePaths: {
        type: 'array',
        items: {
            type: 'string',
        },
    },
    zipPaths: {
        type: 'array',
        items: {
            type: 'string',
        },
    },
    collectionName: {
        type: 'string',
    },
};

export const uploadStatusStore = new Store({
    name: 'upload-status',
    schema: uploadStoreSchema,
});

export const keysStoreSchema: Schema<KeysStoreType> = {
    AnonymizeUserID: {
        type: 'object',
        properties: {
            id: {
                type: 'string',
            },
        },
    },
};

export const keysStore = new Store({
    name: 'keys',
    schema: keysStoreSchema,
});

export const safeStorageSchema: Schema<SafeStorageStoreType> = {
    encryptionKey: {
        type: 'string',
    },
};

export const safeStorageStore = new Store({
    name: 'safeStorage',
    schema: safeStorageSchema,
});
