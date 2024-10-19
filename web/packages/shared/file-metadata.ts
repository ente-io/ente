import { isDevBuild } from "@/base/env";
import { type EnteFile, fileLogID } from "@/media/file";
import {
    decryptPublicMagicMetadata,
    type PublicMagicMetadata,
} from "@/media/file-metadata";

/**
 * On-demand decrypt the public magic metadata for an {@link EnteFile} for code
 * running synchronously.
 *
 * It both modifies the given file object, and also returns the decrypted
 * metadata.
 *
 * We are not expected to be in a scenario where the file gets to the UI without
 * having its public magic metadata decrypted, so this function is a sanity
 * check and should be a no-op in usually. On debug builds it'll throw if it
 * finds its assumptions broken.
 */
export const getPublicMagicMetadataSync = (file: EnteFile) => {
    if (!file.pubMagicMetadata) return undefined;
    if (typeof file.pubMagicMetadata.data == "string") {
        if (isDevBuild)
            throw new Error(
                `Public magic metadata for ${fileLogID(file)} had not been decrypted even when the file reached the UI layer`,
            );
        decryptPublicMagicMetadata(file);
    }
    // This cast is unavoidable in the current setup. We need to refactor the
    // types so that this cast in not needed.
    return file.pubMagicMetadata.data as PublicMagicMetadata;
};
