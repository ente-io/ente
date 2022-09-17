import Store, { Schema } from 'electron-store';
import { SafeStorageStoreType } from '../types';

const safeStorageSchema: Schema<SafeStorageStoreType> = {
    encryptionKey: {
        type: 'string',
    },
};

export const safeStorageStore = new Store({
    name: 'safeStorage',
    schema: safeStorageSchema,
});
