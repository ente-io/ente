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
 * Record the existence of a fileID so that entities in the face indexing
 * universe know about it.
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
