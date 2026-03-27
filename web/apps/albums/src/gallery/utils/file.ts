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
