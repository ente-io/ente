import type { EnteFile } from "@/media/file";

/** Segment the given {@link files} into lists indexed by their collection ID */
export const groupFilesBasedOnCollectionID = (files: EnteFile[]) => {
    const result = new Map<number, EnteFile[]>();
    for (const file of files) {
        const id = file.collectionID;
        if (!result.has(id)) result.set(id, []);
        // See: [Note: strict mode migration]
        //
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore
        result.get(id).push(file);
    }
    return result;
};

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
