import Store, { Schema } from "electron-store";
import type { UploadStoreType } from "../types/main";

const uploadStoreSchema: Schema<UploadStoreType> = {
    filePaths: {
        type: "array",
        items: {
            type: "string",
        },
    },
    zipPaths: {
        type: "array",
        items: {
            type: "string",
        },
    },
    collectionName: {
        type: "string",
    },
};

export const uploadStatusStore = new Store({
    name: "upload-status",
    schema: uploadStoreSchema,
});
