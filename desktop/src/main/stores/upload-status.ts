import Store, { Schema } from "electron-store";

export interface UploadStatusStore {
    /* The collection to which we're uploading, or the root collection. */
    collectionName: string;
    /** Paths to regular files that are pending upload */
    filePaths: string[];
    /**
     * Each item is the path to a zip file and the name of an entry within it.
     *
     * This is marked optional since legacy stores will not have it.
     */
    zipEntries?: [zipPath: string, entryName: string][];
    /** Legacy paths to zip files, now subsumed into zipEntries */
    zipPaths?: string[];
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
    zipEntries: {
        type: "array",
        items: {
            type: "array",
            items: {
                type: "string",
            },
        },
    },
    zipPaths: {
        type: "array",
        items: {
            type: "string",
        },
    },
};

export const uploadStatusStore = new Store({
    name: "upload-status",
    schema: uploadStatusSchema,
});
