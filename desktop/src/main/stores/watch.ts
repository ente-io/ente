import Store, { Schema } from "electron-store";
import { type FolderWatch } from "../../types/ipc";
import log from "../log";

interface WatchStore {
    mappings: FolderWatchWithLegacyFields[];
}

type FolderWatchWithLegacyFields = FolderWatch & {
    /** @deprecated Only retained for migration, do not use in other code */
    rootFolderName?: string;
    /** @deprecated Only retained for migration, do not use in other code */
    uploadStrategy?: number;
};

const watchStoreSchema: Schema<WatchStore> = {
    mappings: {
        type: "array",
        items: {
            type: "object",
            properties: {
                rootFolderName: { type: "string" },
                collectionMapping: { type: "string" },
                uploadStrategy: { type: "number" },
                folderPath: { type: "string" },
                syncedFiles: {
                    type: "array",
                    items: {
                        type: "object",
                        properties: {
                            path: { type: "string" },
                            uploadedFileID: { type: "number" },
                            collectionID: { type: "number" },
                        },
                    },
                },
                ignoredFiles: {
                    type: "array",
                    items: { type: "string" },
                },
            },
        },
    },
};

export const watchStore = new Store({
    name: "watch-status",
    schema: watchStoreSchema,
});

/**
 * Previous versions of the store used to store an integer to indicate the
 * collection mapping, migrate these to the new schema if we encounter them.
 */
export const migrateLegacyWatchStoreIfNeeded = () => {
    let needsUpdate = false;
    const watches = watchStore.get("mappings")?.map((watch) => {
        let collectionMapping = watch.collectionMapping;
        if (!collectionMapping) {
            collectionMapping = watch.uploadStrategy == 1 ? "parent" : "root";
            needsUpdate = true;
        }
        if (watch.rootFolderName) {
            delete watch.rootFolderName;
            needsUpdate = true;
        }
        return { ...watch, collectionMapping };
    });
    if (needsUpdate) {
        watchStore.set("mappings", watches);
        log.info("Migrated legacy watch store data to new schema");
    }
};
