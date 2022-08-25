import Store, { Schema } from 'electron-store';
import { WatchStoreType } from '../types';

const watchStoreSchema: Schema<WatchStoreType> = {
    mappings: {
        type: 'array',
        items: {
            type: 'object',
            properties: {
                rootFolderName: {
                    type: 'string',
                },
                uploadStrategy: {
                    type: 'number',
                },
                folderPath: {
                    type: 'string',
                },
                files: {
                    type: 'array',
                    items: {
                        type: 'object',
                        properties: {
                            path: {
                                type: 'string',
                            },
                            id: {
                                type: 'number',
                            },
                        },
                    },
                },
            },
        },
    },
};

export const watchStore = new Store({
    name: 'watch-status',
    schema: watchStoreSchema,
});
