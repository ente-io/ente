import log from "@/next/log";
import { openDB, type DBSchema } from "idb";
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
        key: string;
        value: FaceIndex;
    };
    "file-status": {
        key: string;
        value: FileStatus;
        indexes: { isIndexed: number };
    };
}

interface FileStatus {
    /** The ID of the {@link EnteFile} whose indexing status we represent. */
    fileID: string;
    /**
     * `1` if we have indexed a file with this {@link fileID}, `0` otherwise.
     *
     * It is guaranteed that "face-index" will have an entry for the same
     * {@link fileID} if and only if {@link isIndexed} is `1`.
     *
     * > Somewhat confusingly, we also have a (IndexedDB) "index" on this field.
     *   That (IDB) index allows us to effectively select {@link fileIDs} that
     *   still need indexing (where {@link isIndexed} is not `1`), so there is
     *   utility, it is just that if I say the word "index" one more time...
     *
     * [Note: Boolean IndexedDB indexes].
     *
     * IndexedDB does not (currently) supported indexes on boolean fields.
     * https://github.com/w3c/IndexedDB/issues/76
     *
     * As a workaround, we use numeric fields where `0` denotes `false` and `1`
     * denotes `true`.
     */
    isIndexed: number;
    /**
     * The number of times attempts to index this file failed.
     *
     * This is guaranteed to be `0` for files which have already been
     * sucessfully indexed (i.e. files for which `isIndexed` is true).
     */
    failureCount: number;
}

// eslint-disable-next-line @typescript-eslint/no-unused-vars
const openFaceDB = () =>
    openDB<FaceDBSchema>("face", 1, {
        upgrade(db, oldVersion, newVersion) {
            log.info(`Upgrading face DB ${oldVersion} => ${newVersion}`);
            if (oldVersion < 1) {
                db.createObjectStore("face-index", { keyPath: "fileID" });

                const statusStore = db.createObjectStore("file-status", {
                    keyPath: "fileID",
                });
                statusStore.createIndex("isIndexed", "isIndexed");
            }
        },
        // TODO: FDB
    });

/**
 * Save the given {@link faceIndex} locally.
 *
 * @param faceIndex A {@link FaceIndex} representing the faces that we detected
 * (and their corresponding embeddings) in some file.
 *
 * This function adds a new entry, overwriting any existing ones (No merging is
 * performed, the existing entry is unconditionally overwritten).
 */
// eslint-disable-next-line @typescript-eslint/no-unused-vars
export const saveFaceIndex = (faceIndex: FaceIndex) => {};

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
// eslint-disable-next-line @typescript-eslint/no-unused-vars
export const addFileEntry = (fileID: string) => {};

/**
 * Increment the failure count associated with the given {@link fileID}.
 *
 * @param fileID The ID of an {@link EnteFile}.
 *
 * If an entry does not exist yet for the given file, then a new one is created
 * and its failure count is set to 1. Otherwise the failure count of the
 * existing entry is incremented.
 */
// eslint-disable-next-line @typescript-eslint/no-unused-vars
export const markIndexingFailed = (fileID: string) => {};

/**
 * Clear any data stored by the face module.
 *
 * Meant to be called during logout.
 */
export const clearFaceData = () => {};
