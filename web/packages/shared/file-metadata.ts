import { isDevBuild } from "@/base/env";
import {
    decryptPublicMagicMetadata,
    type PublicMagicMetadata,
} from "@/media/file-metadata";
import { EnteFile } from "@/new/photos/types/file";
import { fileLogID } from "@/new/photos/utils/file";

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
export const getPublicMagicMetadataSync = (enteFile: EnteFile) => {
    if (!enteFile.pubMagicMetadata) return undefined;
    if (typeof enteFile.pubMagicMetadata.data == "string") {
        if (isDevBuild)
            throw new Error(
                `Public magic metadata for ${fileLogID(enteFile)} had not been decrypted even when the file reached the UI layer`,
            );
        decryptPublicMagicMetadata(enteFile);
    }
    // This cast is unavoidable in the current setup. We need to refactor the
    // types so that this cast in not needed.
    return enteFile.pubMagicMetadata.data as PublicMagicMetadata;
};
