import { haveWindow } from "@/next/env";
import log from "@/next/log";
import {
    DBSchema,
    IDBPDatabase,
    IDBPTransaction,
    StoreNames,
    deleteDB,
    openDB,
} from "idb";
import isElectron from "is-electron";
import type { Person } from "services/face/people";
import type { MlFileData } from "services/face/types-old";
import { MAX_ML_SYNC_ERROR_COUNT } from "services/machineLearning/machineLearningService";

export interface IndexStatus {
    outOfSyncFilesExists: boolean;
    nSyncedFiles: number;
    nTotalFiles: number;
    localFilesSynced: boolean;
    peopleIndexSynced: boolean;
}

/**
 * TODO(MR): Transient type with an intersection of values that both existing
 * and new types during the migration will have. Eventually we'll store the the
 * server ML data shape here exactly.
 */
export interface MinimalPersistedFileData {
    fileId: number;
    mlVersion: number;
    errorCount: number;
    faces?: { personId?: number; id: string }[];
}

interface Config {}

export const ML_SEARCH_CONFIG_NAME = "ml-search";

const MLDATA_DB_NAME = "mldata";
interface MLDb extends DBSchema {
    files: {
        key: number;
        value: MinimalPersistedFileData;
        indexes: { mlVersion: [number, number] };
    };
    people: {
        key: number;
        value: Person;
    };
    // Unused, we only retain this is the schema so that we can delete it during
    // migration.
    things: {
        key: number;
        value: unknown;
    };
    versions: {
        key: string;
        value: number;
    };
    library: {
        key: string;
        value: unknown;
    };
    configs: {
        key: string;
        value: Config;
    };
}

class MLIDbStorage {
    public _db: Promise<IDBPDatabase<MLDb>>;

    constructor() {
        if (!haveWindow() || !isElectron()) {
            return;
        }

        this.db;
    }

    private openDB(): Promise<IDBPDatabase<MLDb>> {
        return openDB<MLDb>(MLDATA_DB_NAME, 4, {
            terminated: async () => {
                log.error("ML Indexed DB terminated");
                this._db = undefined;
                // TODO: remove if there is chance of this going into recursion in some case
                await this.db;
            },
            blocked() {
                // TODO: make sure we dont allow multiple tabs of app
                log.error("ML Indexed DB blocked");
            },
            blocking() {
                // TODO: make sure we dont allow multiple tabs of app
                log.error("ML Indexed DB blocking");
            },
            async upgrade(db, oldVersion, newVersion, tx) {
                let wasMLSearchEnabled = false;
                try {
                    const searchConfig: unknown = await tx
                        .objectStore("configs")
                        .get(ML_SEARCH_CONFIG_NAME);
                    if (
                        searchConfig &&
                        typeof searchConfig == "object" &&
                        "enabled" in searchConfig &&
                        typeof searchConfig.enabled == "boolean"
                    ) {
                        wasMLSearchEnabled = searchConfig.enabled;
                    }
                } catch (e) {
                    // The configs store might not exist (e.g. during logout).
                    // Ignore.
                }
                log.info(
                    `Previous ML database v${oldVersion} had ML search ${wasMLSearchEnabled ? "enabled" : "disabled"}`,
                );

                if (oldVersion < 1) {
                    const filesStore = db.createObjectStore("files", {
                        keyPath: "fileId",
                    });
                    filesStore.createIndex("mlVersion", [
                        "mlVersion",
                        "errorCount",
                    ]);

                    db.createObjectStore("people", {
                        keyPath: "id",
                    });

                    db.createObjectStore("things", {
                        keyPath: "id",
                    });

                    db.createObjectStore("versions");

                    db.createObjectStore("library");
                }
                if (oldVersion < 2) {
                    // TODO: update configs if version is updated in defaults
                    db.createObjectStore("configs");

                    /*
                    await tx
                        .objectStore("configs")
                        .add(
                            DEFAULT_ML_SYNC_JOB_CONFIG,
                            "ml-sync-job",
                        );

                    await tx
                        .objectStore("configs")
                        .add(DEFAULT_ML_SYNC_CONFIG, ML_SYNC_CONFIG_NAME);
                    */
                }
                if (oldVersion < 3) {
                    const DEFAULT_ML_SEARCH_CONFIG = {
                        enabled: false,
                    };

                    await tx
                        .objectStore("configs")
                        .add(DEFAULT_ML_SEARCH_CONFIG, ML_SEARCH_CONFIG_NAME);
                }
                /*
                This'll go in version 5. Note that version 4 was never released,
                but it was in main for a while, so we'll just skip it to avoid
                breaking the upgrade path for people who ran the mainline.
                */
                if (oldVersion < 4) {
                    /*
                    try {
                        await tx
                            .objectStore("configs")
                            .delete(ML_SEARCH_CONFIG_NAME);

                        await tx
                            .objectStore("configs")
                            .delete(""ml-sync"");

                        await tx
                            .objectStore("configs")
                            .delete("ml-sync-job");

                        await tx
                            .objectStore("configs")
                            .add(
                                { enabled: wasMLSearchEnabled },
                                ML_SEARCH_CONFIG_NAME,
                            );

                        db.deleteObjectStore("library");
                        db.deleteObjectStore("things");
                    } catch {
                        // TODO: ignore for now as we finalize the new version
                        // the shipped implementation should have a more
                        // deterministic migration.
                    }
                    */
                }
                log.info(
                    `ML DB upgraded from version ${oldVersion} to version ${newVersion}`,
                );
            },
        });
    }

    public get db(): Promise<IDBPDatabase<MLDb>> {
        if (!this._db) {
            this._db = this.openDB();
            log.info("Opening Ml DB");
        }

        return this._db;
    }

    public async clearMLDB() {
        const db = await this.db;
        db.close();
        await deleteDB(MLDATA_DB_NAME);
        log.info("Cleared Ml DB");
        this._db = undefined;
        await this.db;
    }

    public async getAllFileIdsForUpdate(
        tx: IDBPTransaction<MLDb, ["files"], "readwrite">,
    ) {
        return tx.store.getAllKeys();
    }

    public async getFileIds(
        count: number,
        limitMlVersion: number,
        maxErrorCount: number,
    ) {
        const db = await this.db;
        const tx = db.transaction("files", "readonly");
        const index = tx.store.index("mlVersion");
        let cursor = await index.openKeyCursor(
            IDBKeyRange.upperBound([limitMlVersion], true),
        );

        const fileIds: number[] = [];
        while (cursor && fileIds.length < count) {
            if (
                cursor.key[0] < limitMlVersion &&
                cursor.key[1] <= maxErrorCount
            ) {
                fileIds.push(cursor.primaryKey);
            }
            cursor = await cursor.continue();
        }
        await tx.done;

        return fileIds;
    }

    public async getFile(fileId: number): Promise<MinimalPersistedFileData> {
        const db = await this.db;
        return db.get("files", fileId);
    }

    public async putFile(mlFile: MlFileData) {
        const db = await this.db;
        return db.put("files", mlFile);
    }

    public async upsertFileInTx(
        fileId: number,
        upsert: (mlFile: MinimalPersistedFileData) => MinimalPersistedFileData,
    ) {
        const db = await this.db;
        const tx = db.transaction("files", "readwrite");
        const existing = await tx.store.get(fileId);
        const updated = upsert(existing);
        await tx.store.put(updated);
        await tx.done;

        return updated;
    }

    public async putAllFiles(
        mlFiles: MinimalPersistedFileData[],
        tx: IDBPTransaction<MLDb, ["files"], "readwrite">,
    ) {
        await Promise.all(mlFiles.map((mlFile) => tx.store.put(mlFile)));
    }

    public async removeAllFiles(
        fileIds: Array<number>,
        tx: IDBPTransaction<MLDb, ["files"], "readwrite">,
    ) {
        await Promise.all(fileIds.map((fileId) => tx.store.delete(fileId)));
    }

    public async getPerson(id: number) {
        const db = await this.db;
        return db.get("people", id);
    }

    public async getAllPeople() {
        const db = await this.db;
        return db.getAll("people");
    }

    public async incrementIndexVersion(index: StoreNames<MLDb>) {
        if (index === "versions") {
            throw new Error("versions store can not be versioned");
        }
        const db = await this.db;
        const tx = db.transaction(["versions", index], "readwrite");
        let version = await tx.objectStore("versions").get(index);
        version = (version || 0) + 1;
        tx.objectStore("versions").put(version, index);
        await tx.done;

        return version;
    }

    public async getConfig<T extends Config>(name: string, def: T) {
        const db = await this.db;
        const tx = db.transaction("configs", "readwrite");
        let config = (await tx.store.get(name)) as T;
        if (!config) {
            config = def;
            await tx.store.put(def, name);
        }
        await tx.done;

        return config;
    }

    public async putConfig(name: string, data: Config) {
        const db = await this.db;
        return db.put("configs", data, name);
    }

    public async getIndexStatus(latestMlVersion: number): Promise<IndexStatus> {
        const db = await this.db;
        const tx = db.transaction(["files", "versions"], "readonly");
        const mlVersionIdx = tx.objectStore("files").index("mlVersion");

        let outOfSyncCursor = await mlVersionIdx.openKeyCursor(
            IDBKeyRange.upperBound([latestMlVersion], true),
        );
        let outOfSyncFilesExists = false;
        while (outOfSyncCursor && !outOfSyncFilesExists) {
            if (
                outOfSyncCursor.key[0] < latestMlVersion &&
                outOfSyncCursor.key[1] <= MAX_ML_SYNC_ERROR_COUNT
            ) {
                outOfSyncFilesExists = true;
            }
            outOfSyncCursor = await outOfSyncCursor.continue();
        }

        const nSyncedFiles = await mlVersionIdx.count(
            IDBKeyRange.lowerBound([latestMlVersion]),
        );
        const nTotalFiles = await mlVersionIdx.count();

        const filesIndexVersion = await tx.objectStore("versions").get("files");
        const peopleIndexVersion = await tx
            .objectStore("versions")
            .get("people");
        const filesIndexVersionExists =
            filesIndexVersion !== null && filesIndexVersion !== undefined;
        const peopleIndexVersionExists =
            peopleIndexVersion !== null && peopleIndexVersion !== undefined;

        await tx.done;

        return {
            outOfSyncFilesExists,
            nSyncedFiles,
            nTotalFiles,
            localFilesSynced: filesIndexVersionExists,
            peopleIndexSynced:
                peopleIndexVersionExists &&
                peopleIndexVersion === filesIndexVersion,
        };
    }
}

export default new MLIDbStorage();
