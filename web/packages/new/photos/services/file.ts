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
