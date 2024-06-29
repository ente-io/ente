import type { EnteFile } from "../types/file";

/**
 * [Note: File name for local EnteFile objects]
 *
 * The title property in a file's metadata is the original file's name. The
 * metadata of a file cannot be edited. So if later on the file's name is
 * changed, then the edit is stored in the `editedName` property of the public
 * metadata of the file.
 *
 * This function merges these edits onto the file object that we use locally.
 * Effectively, post this step, the file's metadata.title can be used in lieu of
 * its filename.
 */
export function mergeMetadata(files: EnteFile[]): EnteFile[] {
    return files.map((file) => {
        // TODO: Until the types reflect reality
        // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
        if (file.pubMagicMetadata?.data.editedTime) {
            file.metadata.creationTime = file.pubMagicMetadata.data.editedTime;
        }
        // TODO: Until the types reflect reality
        // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
        if (file.pubMagicMetadata?.data.editedName) {
            file.metadata.title = file.pubMagicMetadata.data.editedName;
        }

        return file;
    });
}
