import { removeKV } from "@/base/kv";
import log from "@/base/log";
import localForage from "@ente/shared/storage/localForage";
import { deleteDB, openDB, type DBSchema } from "idb";
import type { LocalCLIPIndex } from "./clip";
import type { LocalFaceIndex } from "./face";

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
 * - "face-index": Contains {@link LocalFaceIndex} objects, either indexed
 *   locally or fetched from remote.
 *
 * - "clip-index": Contains {@link LocalCLIPIndex} objects, either indexed
 *   locally or fetched from remote.
 *
 * All the stores are keyed by {@link fileID}. The "file-status" contains
 * book-keeping about the indexing process (whether or not a file needs
 * indexing, or if there were errors doing so), while the other stores contain
 * the actual indexing results.
 *
 * In tandem, these serve as the underlying storage for the functions exposed by
 * the ML database.
 */
interface MLDBSchema extends DBSchema {
    "file-status": {
        key: number;
        value: FileStatus;
        indexes: { status: FileStatus["status"] };
    };
    "face-index": {
        key: number;
        value: LocalFaceIndex;
    };
    "clip-index": {
        key: number;
        value: LocalCLIPIndex;
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
     * If you haven't heard the word "index" to the point of zoning out, we also
     * have a (IndexedDB) "index" on the status field to allow us to efficiently
     * select or count {@link fileIDs} that fall into various buckets.
     */
    status: "indexable" | "indexed" | "failed";
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
 * A lazily-created, cached promise for ML DB.
 *
 * See: [Note: Caching IDB instances in separate execution contexts].
 */
let _mlDB: ReturnType<typeof openMLDB> | undefined;

const openMLDB = async () => {
    deleteLegacyDB();

    // TODO-ML: "face" => "ml", v2 => v1
    const db = await openDB<MLDBSchema>("face", 2, {
        upgrade(db, oldVersion, newVersion) {
            log.info(`Upgrading ML DB ${oldVersion} => ${newVersion}`);
            if (oldVersion < 1) {
                db.createObjectStore("file-status", {
                    keyPath: "fileID",
                }).createIndex("status", "status");
                db.createObjectStore("face-index", { keyPath: "fileID" });
            }
            if (oldVersion < 2) {
                db.createObjectStore("clip-index", { keyPath: "fileID" });
            }
        },
        blocking() {
            log.info(
                "Another client is attempting to open a new version of ML DB",
            );
            db.close();
            _mlDB = undefined;
        },
        blocked() {
            log.warn(
                "Waiting for an existing client to close their connection so that we can update the ML DB version",
            );
        },
        terminated() {
            log.warn("Our connection to ML DB was unexpectedly terminated");
            _mlDB = undefined;
        },
    });
    return db;
};

const deleteLegacyDB = () => {
    // Delete the legacy face DB v1.
    //
    // This code was added June 2024 (v1.7.1-rc) and can be removed at some
    // point when most clients have migrated (tag: Migration).
    void deleteDB("mldata");

    // Delete the legacy CLIP (mostly) related keys from LocalForage.
    //
    // This code was added July 2024 (v1.7.2-rc) and can be removed at some
    // point when most clients have migrated (tag: Migration).
    void Promise.all([
        localForage.removeItem("embeddings"),
        localForage.removeItem("embedding_sync_time"),
        localForage.removeItem("embeddings_v2"),
        localForage.removeItem("file_embeddings"),
        localForage.removeItem("onnx-clip-embedding_sync_time"),
        localForage.removeItem("file-ml-clip-face-embedding_sync_time"),
    ]);

    // Delete keys for the legacy diff based sync.
    //
    // This code was added July 2024 (v1.7.3-beta). These keys were never
    // enabled outside of the nightly builds, so this cleanup is not a hard
    // need. Either ways, it can be removed at some point when most clients have
    // migrated (tag: Migration).
    void Promise.all([
        removeKV("embeddingSyncTime:onnx-clip"),
        removeKV("embeddingSyncTime:file-ml-clip-face"),
    ]);

    // Delete legacy ML keys.
    //
    // This code was added August 2024 (v1.7.3-beta) and can be removed at some
    // point when most clients have migrated (tag: Migration).
    localStorage.removeItem("faceIndexingEnabled");
};

/**
 * @returns a lazily created, cached connection to the ML DB.
 */
const mlDB = () => (_mlDB ??= openMLDB());

/**
 * Clear any data stored in the ML DB.
 *
 * This is meant to be called during logout on the main thread.
 */
export const clearMLDB = async () => {
    deleteLegacyDB();

    try {
        if (_mlDB) (await _mlDB).close();
    } catch (e) {
        log.warn("Ignoring error when trying to close ML DB", e);
    }
    _mlDB = undefined;

    return deleteDB("face", {
        blocked() {
            log.warn(
                "Waiting for an existing client to close their connection so that we can delete the ML DB",
            );
        },
    });
};

/**
 * Save the given {@link faceIndex} and {@link clipIndex}, and mark the file as
 * "indexed".
 *
 * This function adds a new entry for the indexes, overwriting any existing ones
 * (No merging is performed, the existing entry is unconditionally overwritten).
 * The file status is also updated to "indexed", and the failure count is reset
 * to 0.
 */
export const saveIndexes = async (
    faceIndex: LocalFaceIndex,
    clipIndex: LocalCLIPIndex,
) => {
    const { fileID } = faceIndex;

    const db = await mlDB();
    const tx = db.transaction(
        ["file-status", "face-index", "clip-index"],
        "readwrite",
    );

    await Promise.all([
        tx.objectStore("file-status").put({
            fileID,
            status: "indexed",
            failureCount: 0,
        }),
        tx.objectStore("face-index").put(faceIndex),
        tx.objectStore("clip-index").put(clipIndex),
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
    failureCount: 0,
});

/**
 * Return the {@link FaceIndex}, if any, for {@link fileID}.
 */
export const faceIndex = async (fileID: number) => {
    const db = await mlDB();
    return db.get("face-index", fileID);
};

/**
 * Return all face indexes present locally.
 */
export const faceIndexes = async () => {
    const db = await mlDB();
    return await db.getAll("face-index");
};

/**
 * Return all CLIP indexes present locally.
 */
export const clipIndexes = async () => {
    const db = await mlDB();
    return await db.getAll("clip-index");
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
    const db = await mlDB();
    const tx = db.transaction("file-status", "readwrite");
    if ((await tx.store.getKey(fileID)) === undefined)
        await tx.store.put(newFileStatus(fileID));
    return tx.done;
};

/**
 * Update entries in ML DB to align with the state of local files outside ML DB.
 *
 * @param localFileIDs IDs of all the files that the client is aware of,
 * filtered to only keep the files that the user owns and the formats that can
 * be indexed by our current indexing pipelines.
 *
 * @param localTrashFilesIDs IDs of all the files in trash.
 *
 * This function then updates the state of file entries in ML DB to the be in
 * sync with these provided local file IDs.
 *
 * - Files that are present locally but are not yet in ML DB get a fresh entry
 *   in face DB (and are marked as indexable).
 *
 * - Files that are not present locally (nor are in trash) but still exist in ML
 *   DB are removed from ML DB (including any indexes).
 *
 * - Files that are not present locally but are in the trash are retained in ML
 *   DB if their status is "indexed"; otherwise they too are removed. This is to
 *   prevent churn, otherwise they'll get unnecessarily reindexed again if the
 *   user restores them from trash before permanent deletion.
 */
export const updateAssumingLocalFiles = async (
    localFileIDs: number[],
    localTrashFilesIDs: number[],
) => {
    const db = await mlDB();
    const tx = db.transaction(
        ["file-status", "face-index", "clip-index"],
        "readwrite",
    );
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
            removedFileIDs.map((id) => tx.objectStore("clip-index").delete(id)),
            tx.done,
        ].flat(),
    );
};

/**
 * Return the count of files that can be, and that have been, indexed.
 *
 * These counts are mutually exclusive. Thus the total number of files that are
 * fall within the purview of the indexer will be indexable + indexed (if we are
 * ignoring the "failed" ones).
 */
export const indexableAndIndexedCounts = async () => {
    const db = await mlDB();
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
 * (we can use {@link addFileEntry} to inform it about new files). From this
 * universe, we filter out fileIDs the files corresponding to which have already
 * been indexed, or which should be ignored.
 *
 * @param count Limit the result to up to {@link count} items.
 */
export const indexableFileIDs = async (count?: number) => {
    const db = await mlDB();
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
 *
 * This count is across all different types of indexing (face, CLIP) that happen
 * on the file.
 */
export const markIndexingFailed = async (fileID: number) => {
    const db = await mlDB();
    const tx = db.transaction("file-status", "readwrite");
    const fileStatus = (await tx.store.get(fileID)) ?? newFileStatus(fileID);
    fileStatus.status = "failed";
    fileStatus.failureCount = fileStatus.failureCount + 1;
    await Promise.all([tx.store.put(fileStatus), tx.done]);
};
