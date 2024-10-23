import type { EnteFile } from "@/media/file";

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

/**
 * Construct a map from file IDs to the list of collections (IDs) to which the
 * file belongs.
 */
export const createFileCollectionIDs = (files: EnteFile[]) =>
    files.reduce((result, file) => {
        const id = file.id;
        let fs = result.get(id);
        if (!fs) result.set(id, (fs = []));
        fs.push(file.collectionID);
        return result;
    }, new Map<number, number[]>());

export function getLatestVersionFiles(files: EnteFile[]) {
    const latestVersionFiles = new Map<string, EnteFile>();
    files.forEach((file) => {
        const uid = `${file.collectionID}-${file.id}`;
        if (
            !latestVersionFiles.has(uid) ||
            // See: [Note: strict mode migration]
            //
            // eslint-disable-next-line @typescript-eslint/ban-ts-comment
            // @ts-ignore
            latestVersionFiles.get(uid).updationTime < file.updationTime
        ) {
            latestVersionFiles.set(uid, file);
        }
    });
    return Array.from(latestVersionFiles.values()).filter(
        (file) => !file.isDeleted,
    );
}
