import Store, { Schema } from 'electron-store';
import { KeysStoreType } from '../types';

const keysStoreSchema: Schema<KeysStoreType> = {
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
