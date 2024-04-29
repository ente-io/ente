import Store, { Schema } from "electron-store";

export interface UploadStatusStore {
    /**
     * The name of the collection (when uploading to a singular collection) or
     * the root collection (when uploading to separate * albums) to which we
     * these uploads are meant to go to.
     */
    collectionName: string;
    /**
     * Paths of regular files that need to be uploaded.
     */
    filePaths: string[];
    /**
     * Paths of zip files that need to be uploaded.
     */
    zipPaths: string[];
    /**
     * For each zip file, which of its entries (paths) within the zip file that
     * need to be uploaded.
     */
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
