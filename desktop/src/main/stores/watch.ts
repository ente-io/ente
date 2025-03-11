import Store, { Schema } from "electron-store";
import { type FolderWatch } from "../../types/ipc";
import log from "../log";

interface WatchStore {
    mappings?: FolderWatchWithLegacyFields[];
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
                ignoredFiles: { type: "array", items: { type: "string" } },
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
    const updatedWatches = [];
    for (const watch of watchStore.get("mappings") ?? []) {
        let collectionMapping = watch.collectionMapping;
        // The required type defines the latest schema, but before migration
        // this'll be undefined, so tell ESLint to calm down.
        // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
        if (!collectionMapping) {
            // eslint-disable-next-line @typescript-eslint/no-deprecated
            collectionMapping = watch.uploadStrategy == 1 ? "parent" : "root";
            needsUpdate = true;
        }
        // eslint-disable-next-line @typescript-eslint/no-deprecated
        if (watch.rootFolderName) {
            // eslint-disable-next-line @typescript-eslint/no-deprecated
            delete watch.rootFolderName;
            needsUpdate = true;
        }
        updatedWatches.push({ ...watch, collectionMapping });
    }
    if (needsUpdate) {
        watchStore.set("mappings", updatedWatches);
        log.info("Migrated legacy watch store data to new schema");
    }
};
