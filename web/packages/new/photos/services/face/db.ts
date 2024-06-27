import log from "@/next/log";
import { deleteDB, openDB, type DBSchema } from "idb";
import type { FaceIndex } from "./types";

/**
 * [Note: Face DB schema]
 *
 * There "face" database is made of two object stores:
 *
 * - "face-index": Contains {@link FaceIndex} objects, either indexed locally or
 *   fetched from remote storage.
 *
 * - "file-status": Contains {@link FileStatus} objects, one for each
 *   {@link EnteFile} that the current client knows about.
 *
 * Both the stores are keyed by {@link fileID}, and are expected to contain the
 * exact same set of {@link fileID}s. The face-index can be thought of as the
 * "original" indexing result, whilst file-status bookkeeps information about
 * the indexing process (whether or not a file needs indexing, or if there were
 * errors doing so).
 *
 * In tandem, these serve as the underlying storage for the functions exposed by
 * this file.
 */
interface FaceDBSchema extends DBSchema {
    "face-index": {
        key: number;
        value: FaceIndex;
    };
    "file-status": {
        key: number;
        value: FileStatus;
        indexes: { status: FileStatus["status"] };
    };
}

interface FileStatus {
    /** The ID of the {@link EnteFile} whose indexing status we represent. */
    fileID: number;
    /**
     * The status of the file.
     *
     * - "indexable" - This file is something that we can index, but it is yet
     *   to be indexed.
     *
     * - "indexed" - We have a corresponding entry for this file in the
     *   "face-index" object (either indexed locally or fetched from remote).
     *
     * - "failed" - Indexing was attempted but failed.
     *
     * We also have a (IndexedDB) "index" on this field to allow us to
     * efficiently select or count {@link fileIDs} that fall into various
     * buckets.
     */
    status: "indexable" | "indexed" | "failed";
    /**
     * The number of times attempts to index this file failed.
     *
     * This is guaranteed to be `0` for files with status "indexed".
     */
    failureCount: number;
}

/**
 * A promise to the face DB.
 *
 * We open the database once (lazily), and thereafter save and reuse the promise
 * each time something wants to connect to it.
 *
 * This promise can subsequently get cleared if we need to relinquish our
 * connection (e.g. if another client wants to open the face DB with a newer
 * version of the schema).
 *
 * Note that this is module specific state, so the main thread and each worker
 * thread that calls the functions in this module will have their own promises.
 * To ensure that all connections get torn down correctly, we need to call
 * {@link closeFaceDBConnectionsIfNeeded} from both the main thread and all the
 * worker threads that use this module.
 */
let _faceDB: ReturnType<typeof openFaceDB> | undefined;

const openFaceDB = async () => {
    deleteLegacyDB();

    const db = await openDB<FaceDBSchema>("face", 1, {
        upgrade(db, oldVersion, newVersion) {
            log.info(`Upgrading face DB ${oldVersion} => ${newVersion}`);
            if (oldVersion < 1) {
                db.createObjectStore("face-index", { keyPath: "fileID" });
                db.createObjectStore("file-status", {
                    keyPath: "fileID",
                }).createIndex("status", "status");
            }
        },
        blocking() {
            log.info(
                "Another client is attempting to open a new version of face DB",
            );
            db.close();
            _faceDB = undefined;
        },
        blocked() {
            log.warn(
                "Waiting for an existing client to close their connection so that we can update the face DB version",
            );
        },
        terminated() {
            log.warn("Our connection to face DB was unexpectedly terminated");
            _faceDB = undefined;
        },
    });
    return db;
};

const deleteLegacyDB = () => {
    // Delete the legacy face DB.
    // This code was added June 2024 (v1.7.1-rc) and can be removed once clients
    // have migrated over.
    void deleteDB("mldata");
};

/**
 * @returns a lazily created, cached connection to the face DB.
 */
const faceDB = () => (_faceDB ??= openFaceDB());

/**
 * Close the face DB connection (if any) opened by this module.
 *
 * To ensure proper teardown of the DB connections, this function must be called
 * at least once by any execution context that has called any of the other
 * functions in this module.
 */
export const closeFaceDBConnectionsIfNeeded = async () => {
    try {
        if (_faceDB) (await _faceDB).close();
    } finally {
        _faceDB = undefined;
    }
};

/**
 * Clear any data stored by the face module.
 *
 * Meant to be called during logout.
 */
export const clearFaceData = async () => {
    deleteLegacyDB();
    await closeFaceDBConnectionsIfNeeded();
    return deleteDB("face", {
        blocked() {
            log.warn(
                "Waiting for an existing client to close their connection so that we can delete the face DB",
            );
        },
    });
};

/**
 * Save the given {@link faceIndex} locally.
 *
 * @param faceIndex A {@link FaceIndex} representing the faces that we detected
 * (and their corresponding embeddings) in some file.
 *
 * This function adds a new entry, overwriting any existing ones (No merging is
 * performed, the existing entry is unconditionally overwritten).
 */
export const saveFaceIndex = async (faceIndex: FaceIndex) => {
    const db = await faceDB();
    const tx = db.transaction(["face-index", "file-status"], "readwrite");
    const indexStore = tx.objectStore("face-index");
    const statusStore = tx.objectStore("file-status");
    await Promise.all([
        indexStore.put(faceIndex),
        statusStore.put({
            fileID: faceIndex.fileID,
            status: "indexed",
            failureCount: 0,
        }),
        tx.done,
    ]);
};

/**
 * Return the {@link FaceIndex}, if any, for {@link fileID}.
 */
export const faceIndex = async (fileID: number) => {
    const db = await faceDB();
    return db.get("face-index", fileID);
};

/**
 * Record the existence of a file so that entities in the face indexing universe
 * know about it (e.g. can index it if it is new and it needs indexing).
 *
 * @param fileID The ID of an {@link EnteFile}.
 *
 * This function does not overwrite existing entries. If an entry already exists
 * for the given {@link fileID} (e.g. if it was indexed and
 * {@link saveFaceIndex} called with the result), its existing status remains
 * unperturbed.
 */
export const addFileEntry = async (fileID: number) => {
    const db = await faceDB();
    const tx = db.transaction("file-status", "readwrite");
    if ((await tx.store.getKey(fileID)) === undefined) {
        await tx.store.put({
            fileID,
            status: "indexable",
            failureCount: 0,
        });
    }
    return tx.done;
};

/**
 * Sync entries in the face DB to align with the state of local files outside
 * face DB.
 *
 * @param localFileIDs IDs of all the files that the client is aware of filtered
 * to only keep the files that the user owns and the formats that can be indexed
 * by our current face indexing pipeline.
 *
 * @param localFilesInTrashIDs IDs of all the files in trash.
 *
 * This function then updates the state of file entries in face DB to the be in
 * "sync" with these provided local file IDS.
 *
 * - Files that are present locally but are not yet in face DB get a fresh entry
 *   in face DB (and are marked as indexable).
 *
 * - Files that are not present locally (nor are in trash) but still exist in
 *   face DB are removed from face DB (including their face index, if any).
 *
 * - Files that are not present locally but are in the trash are retained in
 *   face DB if their status is "indexed" (otherwise they too are removed). This
 *   is prevent churn (re-indexing) if the user moves some files to trash but
 *   then later restores them before they get permanently deleted.
 */
export const syncAssumingLocalFileIDs = async (
    localFileIDs: number[],
    localFilesInTrashIDs: number[],
) => {
    const db = await faceDB();
    const tx = db.transaction(["face-index", "file-status"], "readwrite");
    const fdbFileIDs = await tx.objectStore("file-status").getAllKeys();
    const fdbIndexedFileIDs = await tx
        .objectStore("file-status")
        .getAllKeys(IDBKeyRange.only("indexed"));

    const local = new Set(localFileIDs);
    const localTrash = new Set(localFilesInTrashIDs);
    const fdb = new Set(fdbFileIDs);
    const fdbIndexed = new Set(fdbIndexedFileIDs);

    const newFileIDs = localFileIDs.filter((id) => !fdb.has(id));
    const fileIDsToRemove = fdbFileIDs.filter((id) => {
        if (local.has(id)) return false; // Still exists
        if (localTrash.has(id)) {
            // Exists in trash
            if (fdbIndexed.has(id)) {
                // But is already indexed, so let it be.
                return false;
            }
        }
        return true; // Remove
    });

    await Promise.all(
        [
            newFileIDs.map((id) =>
                tx.objectStore("file-status").put({
                    fileID: id,
                    status: "indexable",
                    failureCount: 0,
                }),
            ),
            fileIDsToRemove.map((id) =>
                tx.objectStore("file-status").delete(id),
            ),
            fileIDsToRemove.map((id) =>
                tx.objectStore("face-index").delete(id),
            ),
            tx.done,
        ].flat(),
    );
};

/**
 * Return the count of files that can be, and that have been, indexed.
 *
 * These counts are mutually exclusive. The total number of files that fall
 * within the purview of the indexer is thus indexable + indexed.
 */
export const indexedAndIndexableCounts = async () => {
    const db = await faceDB();
    const tx = db.transaction("file-status", "readwrite");
    const indexableCount = await tx.store
        .index("status")
        .count(IDBKeyRange.only("indexable"));
    const indexedCount = await tx.store
        .index("status")
        .count(IDBKeyRange.only("indexed"));
    return { indexableCount, indexedCount };
};

/**
 * Return a list of fileIDs that need to be indexed.
 *
 * This list is from the universe of the file IDs that the face DB knows about
 * (can use {@link addFileEntry} to inform it about new files). From this
 * universe, we filter out fileIDs the files corresponding to which have already
 * been indexed, or which should be ignored.
 *
 * @param count Limit the result to up to {@link count} items.
 */
export const indexableFileIDs = async (count?: number) => {
    const db = await faceDB();
    const tx = db.transaction("file-status", "readonly");
    return tx.store
        .index("status")
        .getAllKeys(IDBKeyRange.only("indexable"), count);
};

/**
 * Increment the failure count associated with the given {@link fileID}.
 *
 * @param fileID The ID of an {@link EnteFile}.
 *
 * If an entry does not exist yet for the given file, then a new one is created
 * and its failure count is set to 1. Otherwise the failure count of the
 * existing entry is incremented.
 */
export const markIndexingFailed = async (fileID: number) => {
    const db = await faceDB();
    const tx = db.transaction("file-status", "readwrite");
    const failureCount = ((await tx.store.get(fileID))?.failureCount ?? 0) + 1;
    await tx.store.put({
        fileID,
        status: "failed",
        failureCount,
    });
    return tx.done;
};
