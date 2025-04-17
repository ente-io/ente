import Store, { Schema } from "electron-store";

export interface UploadStatusStore {
    /**
     * The collection to which we're uploading, or the root collection.
     *
     * Not all pending uploads will have an associated collection.
     */
    collectionName?: string;
    /**
     * Paths to regular files that are pending upload.
     */
    filePaths?: string[];
    /**
     * Each item is the path to a zip file and the name of an entry within it.
     */
    zipItems?: [zipPath: string, entryName: string][];
    /**
     * @deprecated Legacy paths to zip files, now subsumed into zipItems.
     */
    zipPaths?: string[];
}

const uploadStatusSchema: Schema<UploadStatusStore> = {
    collectionName: { type: "string" },
    filePaths: { type: "array", items: { type: "string" } },
    zipItems: {
        type: "array",
        items: { type: "array", items: { type: "string" } },
    },
    zipPaths: { type: "array", items: { type: "string" } },
};

export const uploadStatusStore = new Store({
    name: "upload-status",
    schema: uploadStatusSchema,
});
