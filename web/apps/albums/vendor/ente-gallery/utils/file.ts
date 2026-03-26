import type { EnteFile } from "ente-media/file";
import { fileCreationTime } from "ente-media/file-metadata";

/**
 * Sort the given list of {@link EnteFile}s in place.
 *
 * Like the JavaScript Array#sort, this method modifies the {@link files}
 * argument. It sorts {@link files} in place, and then returns a reference to
 * the same mutated array.
 *
 * By default, files are sorted so that the newest one is first. The optional
 * {@link sortAsc} flag can be set to `true` to sort them so that the oldest one
 * is first.
 */
export const sortFiles = (files: EnteFile[], sortAsc = false) => {
    // Sort based on the time of creation time of the file.
    //
    // For files with same creation time, sort based on the time of last
    // modification.
    const factor = sortAsc ? -1 : 1;
    return files.sort((a, b) => {
        const at = fileCreationTime(a);
        const bt = fileCreationTime(b);
        return at == bt
            ? factor *
                  (b.metadata.modificationTime - a.metadata.modificationTime)
            : factor * (bt - at);
    });
};

/**
 * [Note: Collection file]
 *
 * File IDs themselves are unique across all the files for the user (in fact,
 * they're unique across all the files in an Ente instance).
 *
 * However, we can have multiple entries for the same file ID in our local
 * database and/or remote responses because the unit of account is not file, but
 * a "Collection File" – a collection and file pair.
 *
 * For example, if the same file is symlinked into two collections, then we will
 * have two "Collection File" entries for it, both with the same file ID, but
 * with different collection IDs.
 *
 * This function returns files such that only one of these entries is returned.
 * The entry that is returned is arbitrary in general, this function just picks
 * the first one for each unique file ID.
 *
 * If this function is invoked on a list on which {@link sortFiles} has already
 * been called, which by default sorts such that the newest file is first, then
 * this function's behaviour would be to return the newest file from among
 * multiple files with the same ID but different collections.
 */
export const uniqueFilesByID = (files: EnteFile[]) => {
    const seen = new Set<number>();
    return files.filter(({ id }) => {
        if (seen.has(id)) return false;
        seen.add(id);
        return true;
    });
};

/**
 * Segment the given {@link files} into lists indexed by their collection ID.
 *
 * Order is preserved.
 */
export const groupFilesByCollectionID = (files: EnteFile[]) =>
    files.reduce((result, file) => {
        const id = file.collectionID;
        let cfs = result.get(id);
        if (!cfs) result.set(id, (cfs = []));
        cfs.push(file);
        return result;
    }, new Map<number, EnteFile[]>());
