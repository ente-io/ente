import type { EnteFile } from "ente-media/file";
import { fileCreationPhotoSortTime } from "ente-media/file-metadata";

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
    // Sort based on the local photo creation date shown in the UI.
    //
    // For files with same creation date, sort based on the time of last
    // modification.
    const factor = sortAsc ? -1 : 1;
    const sortTimeByFile = new Map<EnteFile, number>();
    const sortTimeForFile = (file: EnteFile) => {
        const cached = sortTimeByFile.get(file);
        if (cached != undefined) return cached;
        const t = fileCreationPhotoSortTime(file);
        sortTimeByFile.set(file, t);
        return t;
    };
    return files.sort((a, b) => {
        const at = sortTimeForFile(a);
        const bt = sortTimeForFile(b);
        return at == bt
            ? factor *
                  (b.metadata.modificationTime - a.metadata.modificationTime)
            : factor * (bt - at);
    });
};
