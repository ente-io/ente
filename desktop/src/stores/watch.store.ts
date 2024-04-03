import Store, { Schema } from "electron-store";
import { WatchStoreType } from "../types/ipc";

const watchStoreSchema: Schema<WatchStoreType> = {
    mappings: {
        type: "array",
        items: {
            type: "object",
            properties: {
                rootFolderName: {
                    type: "string",
                },
                uploadStrategy: {
                    type: "number",
                },
                folderPath: {
                    type: "string",
                },
                syncedFiles: {
                    type: "array",
                    items: {
                        type: "object",
                        properties: {
                            path: {
                                type: "string",
                            },
                            id: {
                                type: "number",
                            },
                        },
                    },
                },
                ignoredFiles: {
                    type: "array",
                    items: {
                        type: "string",
                    },
                },
            },
        },
    },
};

export const watchStore = new Store({
    name: "watch-status",
    schema: watchStoreSchema,
});
