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
        indexes: { isIndexable: number };
    };
}

interface FileStatus {
    /** The ID of the {@link EnteFile} whose indexing status we represent. */
    fileID: number;
    /**
     * `1` if this file needs to be indexed, `0` otherwise.
     *
     * > Somewhat confusingly, we also have a (IndexedDB) "index" on this field.
     *   That (IDB) index allows us to efficiently select {@link fileIDs} that
     *   still need indexing (i.e. entries where {@link isIndexed} is `1`).
     *
     * [Note: Boolean IndexedDB indexes].
     *
     * IndexedDB does not (currently) supported indexes on boolean fields.
     * https://github.com/w3c/IndexedDB/issues/76
     *
     * As a workaround, we use numeric fields where `0` denotes `false` and `1`
     * denotes `true`.
     */
    isIndexable: number;
    /**
     * The number of times attempts to index this file failed.
     *
     * This is guaranteed to be `0` for files which have already been
     * sucessfully indexed (i.e. files for which `isIndexable` is 0 and which
     * have a corresponding entry in the "face-index" object store).
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
    const db = await openDB<FaceDBSchema>("face", 1, {
        upgrade(db, oldVersion, newVersion) {
            log.info(`Upgrading face DB ${oldVersion} => ${newVersion}`);
            if (oldVersion < 1) {
                db.createObjectStore("face-index", { keyPath: "fileID" });
                db.createObjectStore("file-status", {
                    keyPath: "fileID",
                }).createIndex("isIndexable", "isIndexable");
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
    return Promise.all([
        indexStore.put(faceIndex),
        statusStore.put({
            fileID: faceIndex.fileID,
            isIndexable: 0,
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
            isIndexable: 1,
            failureCount: 0,
        });
    }
    return tx.done;
};

/**
 * Sync entries in the face DB to align with the given list of local indexable
 * file IDs.
 *
 * @param localFileIDs The IDs of all the files that the client is aware of,
 * filtered to only keep the files that the user owns and the formats that can
 * be indexed by our current face indexing pipeline.
 *
 * This function syncs the state of file entries in face DB to the state of file
 * entries stored otherwise by the local client.
 *
 * - Files (identified by their ID) that are present locally but are not yet in
 *   face DB get a fresh entry in face DB (and are marked as indexable).
 *
 * - Files that are not present locally but still exist in face DB are removed
 *   from face DB (including its face index, if any).
 */
export const syncWithLocalIndexableFileIDs = async (localFileIDs: number[]) => {
    const db = await faceDB();
    const tx = db.transaction(["face-index", "file-status"], "readwrite");
    const fdbFileIDs = await tx.objectStore("file-status").getAllKeys();

    const local = new Set(localFileIDs);
    const fdb = new Set(fdbFileIDs);

    const newFileIDs = localFileIDs.filter((id) => !fdb.has(id));
    const removedFileIDs = fdbFileIDs.filter((id) => !local.has(id));

    return Promise.all(
        [
            newFileIDs.map((id) =>
                tx.objectStore("file-status").put({
                    fileID: id,
                    isIndexable: 1,
                    failureCount: 0,
                }),
            ),
            removedFileIDs.map((id) =>
                tx.objectStore("file-status").delete(id),
            ),
            removedFileIDs.map((id) => tx.objectStore("face-index").delete(id)),
            tx.done,
        ].flat(),
    );
};

/**
 * Return the count of files that can be, and that have been, indexed.
 */
export const indexedAndIndexableCounts = async () => {
    const db = await faceDB();
    const tx = db.transaction(["face-index", "file-status"], "readwrite");
    const indexedCount = await tx.objectStore("face-index").count();
    const indexableCount = await tx
        .objectStore("file-status")
        .index("isIndexable")
        .count(IDBKeyRange.only(1));
    return { indexedCount, indexableCount };
};

/**
 * Return a list of fileIDs that need to be indexed.
 *
 * This list is from the universe of the file IDs that the face DB knows about
 * (can use {@link addFileEntry} to inform it about new files). From this
 * universe, we filter out fileIDs the files corresponding to which have already
 * been indexed, or for which we attempted indexing but failed.
 *
 * @param count Limit the result to up to {@link count} items.
 */
export const unindexedFileIDs = async (count?: number) => {
    const db = await faceDB();
    const tx = db.transaction("file-status", "readonly");
    return tx.store.index("isIndexable").getAllKeys(IDBKeyRange.only(1), count);
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
    const failureCount = ((await tx.store.get(fileID)).failureCount ?? 0) + 1;
    await tx.store.put({
        fileID,
        isIndexable: 0,
        failureCount,
    });
    return tx.done;
};
