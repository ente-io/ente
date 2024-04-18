import Store, { Schema } from "electron-store";

export interface UploadStatusStore {
    filePaths: string[];
    zipPaths: string[];
    collectionName: string;
}

const uploadStatusSchema: Schema<UploadStatusStore> = {
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
    schema: uploadStatusSchema,
});
