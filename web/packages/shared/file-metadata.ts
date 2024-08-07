import { decryptPublicMagicMetadata } from "@/media/file-metadata";
import { EnteFile } from "@/new/photos/types/file";
import ComlinkCryptoWorker from "@ente/shared/crypto";

/**
 * On-demand decrypt the public magic metadata for an {@link EnteFile} for code
 * running on the main thread.
 *
 * It both modifies the given file object, and also returns the decrypted
 * metadata.
 */
export const getPublicMagicMetadataMT = async (enteFile: EnteFile) =>
    decryptPublicMagicMetadata(
        enteFile,
        (await ComlinkCryptoWorker.getInstance()).decryptMetadata,
    );
