import log from "@/next/log";
import { deleteDB, openDB, type DBSchema } from "idb";
import type { EmbeddingModel } from "./embedding";
import type { FaceIndex } from "./face";

/**
 * ML DB schema.
 *
 * The "ML" database is made of three object stores:
 *
 * - "file-status": Contains {@link FileStatus} objects, one for each
 *   {@link EnteFile} that the ML subsystem knows about. Periodically (and when
 *   required), this is synced with the list of files that the current client
 *   knows about locally.
 *
 * - "face-index": Contains {@link FaceIndex} objects, either indexed locally or
 *   fetched from remote storage.
 *
 * - "clip-index": Contains {@link CLIPIndex} objects, either indexed locally or
 *   fetched from remote storage.
 *
 * All the stores are keyed by {@link fileID}. The "file-status" contains
 * book-keeping about the indexing process (whether or not a file needs
 * indexing, or if there were errors doing so), while the other stores contain
 * the actual indexing results.
 *
 * In tandem, these serve as the underlying storage for the functions exposed by
 * this file.
 */
interface FaceDBSchema extends DBSchema {
    "file-status": {
        key: number;
        value: FileStatus;
        indexes: { status: FileStatus["status"] };
    };
    "face-index": {
        key: number;
        value: FaceIndex;
    };
    "clip-index": {
        key: number;
        value: CLIPIndex;
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
     *   "face-index" _and_ "clip-index" object stores (either indexed locally
     *   or fetched from remote).
     *
     * - "failed" - Indexing was attempted but failed.
     *
     * There can arise situations in which a file has one, but not all, indexes.
     * e.g. it may have a "face-index" but "clip-index" might've not yet
     * happened (or failed). In such cases, the status of the file will be
     * "indexable": it transitions to "indexed" only after all indexes have been
     * computed or fetched.
     *
     * If you have't heard the word "index" to the point of zoning out, we also
     * have a (IndexedDB) "index" on the status field to allow us to efficiently
     * select or count {@link fileIDs} that fall into various buckets.
     */
    status: "indexable" | "indexed" | "failed";
    /**
     * A list of embeddings that we still need to compute for the file.
     *
     * This is guaranteed to be empty if status is "indexed", and will have at
     * least one entry otherwise.
     */
    pending: EmbeddingModel[];
    /**
     * The number of times attempts to index this file failed.
     *
     * It counts failure across all index types.
     *
     * This is guaranteed to be `0` for files with status "indexed".
     */
    failureCount: number;
}

/**
 * A lazily-created, cached promise for face DB.
 *
 * See: [Note: Caching IDB instances in separate execution contexts].
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
 * Clear any data stored in the face DB.
 *
 * This is meant to be called during logout in the main thread.
 */
export const clearFaceDB = async () => {
    deleteLegacyDB();

    try {
        if (_faceDB) (await _faceDB).close();
    } catch (e) {
        log.warn("Ignoring error when trying to close face DB", e);
    }
    _faceDB = undefined;

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
 * (and their corresponding embeddings) in a particular file.
 *
 * This function adds a new entry for the face index, overwriting any existing
 * ones (No merging is performed, the existing entry is unconditionally
 * overwritten). The file status is updated to remove the entry for face from
 * the pending embeddings. If there are no other pending embeddings, the
 * status changes to "indexed".
 */
export const saveFaceIndex = async (faceIndex: FaceIndex) => {
    const { fileID } = faceIndex;

    const db = await faceDB();
    const tx = db.transaction(["face-index", "file-status"], "readwrite");
    const indexStore = tx.objectStore("face-index");
    const statusStore = tx.objectStore("file-status");

    const fileStatus =
        (await statusStore.get(IDBKeyRange.only(fileID))) ??
        newFileStatus(fileID);
    fileStatus.pending = fileStatus.pending.filter(
        (v) => v != "file-ml-clip-face",
    );
    if (fileStatus.pending.length == 0) fileStatus.status = "indexed";

    await Promise.all([
        indexStore.put(faceIndex),
        statusStore.put(fileStatus),
        tx.done,
    ]);
};

/**
 * Return a new object suitable for use as the initial value of the entry for a
 * file in the file status store.
 */
const newFileStatus = (fileID: number): FileStatus => ({
    fileID,
    status: "indexable",
    // TODO-ML:
    // pending: ["file-ml-clip-face", "onnx-clip"],
    pending: ["file-ml-clip-face"],
    failureCount: 0,
});

/**
 * Return the {@link FaceIndex}, if any, for {@link fileID}.
 */
export const faceIndex = async (fileID: number) => {
    const db = await faceDB();
    return db.get("face-index", fileID);
};

/**
 * Record the existence of a file so that entities in the ML universe know about
 * it (e.g. can index it if it is new and it needs indexing).
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
    if ((await tx.store.getKey(fileID)) === undefined)
        await tx.store.put(newFileStatus(fileID));
    return tx.done;
};

/**
 * Update entries in the face DB to align with the state of local files outside
 * face DB.
 *
 * @param localFileIDs IDs of all the files that the client is aware of filtered
 * to only keep the files that the user owns and the formats that can be indexed
 * by our current face indexing pipeline.
 *
 * @param localTrashFilesIDs IDs of all the files in trash.
 *
 * This function then updates the state of file entries in face DB to the be in
 * sync with these provided local file IDS.
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
export const updateAssumingLocalFiles = async (
    localFileIDs: number[],
    localTrashFilesIDs: number[],
) => {
    const db = await faceDB();
    const tx = db.transaction(["face-index", "file-status"], "readwrite");
    const fdbFileIDs = await tx.objectStore("file-status").getAllKeys();
    const fdbIndexedFileIDs = await tx
        .objectStore("file-status")
        .getAllKeys(IDBKeyRange.only("indexed"));

    const local = new Set(localFileIDs);
    const localTrash = new Set(localTrashFilesIDs);
    const fdb = new Set(fdbFileIDs);
    const fdbIndexed = new Set(fdbIndexedFileIDs);

    const newFileIDs = localFileIDs.filter((id) => !fdb.has(id));
    const removedFileIDs = fdbFileIDs.filter((id) => {
        if (local.has(id)) return false; // Still exists.
        if (localTrash.has(id)) {
            // Exists in trash.
            if (fdbIndexed.has(id)) {
                // But is already indexed, so let it be.
                return false;
            }
        }
        return true; // Remove.
    });

    await Promise.all(
        [
            newFileIDs.map((id) =>
                tx.objectStore("file-status").put(newFileStatus(id)),
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
 *
 * These counts are mutually exclusive. The total number of files that fall
 * within the purview of the indexer is thus indexable + indexed.
 */
export const indexableAndIndexedCounts = async () => {
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
    const fileStatus = (await tx.store.get(fileID)) ?? newFileStatus(fileID);
    fileStatus.status = "failed";
    fileStatus.failureCount = fileStatus.failureCount + 1;
    await Promise.all([tx.store.put(fileStatus), tx.done]);
};
