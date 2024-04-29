import Store, { Schema } from "electron-store";

export interface UploadStatusStore {
    collectionName: string;
    filePaths: string[];
    zipPaths: string[];
    zipEntries: Record<string, string[]>;
}

const uploadStatusSchema: Schema<UploadStatusStore> = {
    collectionName: {
        type: "string",
    },
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
    zipEntries: {
        type: "object",
    },
};

export const uploadStatusStore = new Store({
    name: "upload-status",
    schema: uploadStatusSchema,
});
