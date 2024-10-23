import { encryptBlobB64 } from "@/base/crypto";
import { authenticatedRequestHeaders, ensureOk } from "@/base/http";
import { apiURL } from "@/base/origins";
import type { EnteFile } from "@/media/file";
import { z } from "zod";

/**
 * [Note: File data APIs]
 *
 * Remote provides some APIs that talk in terms of "file data", which refers to
 * all the files (original or derived) associated with an {@link EnteFile}.
 *
 * For example, for each original image that the user uploads, there will be an
 * associated thumbnail file, potentially one or more preview files (optimized
 * for size or compatibility across devices), various ML embeddings generated
 * for that file, and possibly more such files in the future.
 *
 * There are specialized APIs for fetching and uploading the originals and the
 * thumbnails. But for the other associated data, we can use the file data APIs.
 */
type FileDataType = "mldata" /* See: [Note: "mldata" format] */;

const RemoteFileData = z.object({
    /**
     * The ID of the {@link EnteFile} with which this file data is associated.
     */
    fileID: z.number(),
    /**
     * Base64 representation of the encrypted data. Its plaintext contents will
     * be specific to each file data type.
     */
    encryptedData: z.string(),
    /**
     * Base64 representation of the header that should be passed when decrypting
     * {@link encryptedData}. See the {@link decryptMetadata} function in the
     * crypto layer.
     */
    decryptionHeader: z.string(),
});

type RemoteFileData = z.infer<typeof RemoteFileData>;

/**
 * Fetch file data of a particular type for the given list of files.
 *
 * @param type The {@link FileDataType} which we want.
 *
 * @param fileIDs The ids of the files for which we want the file data.
 *
 * @returns a list of {@link RemoteFileData} items for the files which had file
 * data for the given type, and that remote was able to successfully retrieve.
 *
 * The order of this list is arbitrary, and the caller should use the
 * {@link fileID} present within the {@link RemoteFileData} to associate an item
 * in the result back to a file instead of relying on the order or count of
 * items in the result.
 *
 * In rare cases (issues with the upstream object storage), it is possible for
 * remote to not return entries for a particular file even though it has
 * associated data of that type. Such skipped entries are mentioned in the
 * payload, but we don't parse that information currently since the higher
 * levels of our code that use this function handle such rare skips gracefully.
 */
export const fetchFileData = async (
    type: FileDataType,
    fileIDs: number[],
): Promise<RemoteFileData[]> => {
    const res = await fetch(await apiURL("/files/data/fetch"), {
        method: "POST",
        headers: await authenticatedRequestHeaders(),
        body: JSON.stringify({ type, fileIDs }),
    });
    ensureOk(res);
    return z.object({ data: z.array(RemoteFileData) }).parse(await res.json())
        .data;
};

/**
 * Upload file data associated with the given file to remote.
 *
 * This function will save or update the given data as the latest file data of
 * {@link type} associated with the given {@link file}. The data will be
 * end-to-end encrypted using the given {@link file}'s key before uploading.
 *
 * @param file {@link EnteFile} which this data is associated with.
 *
 * @param type The {@link FileDataType} which we are uploading.
 *
 * @param data The binary data to upload. The exact contents of the data are
 * {@link type} specific.
 */
export const putFileData = async (
    file: EnteFile,
    type: FileDataType,
    data: Uint8Array,
) => {
    const { encryptedData, decryptionHeader } = await encryptBlobB64(
        data,
        file.key,
    );

    const res = await fetch(await apiURL("/files/data"), {
        method: "PUT",
        headers: await authenticatedRequestHeaders(),
        body: JSON.stringify({
            fileID: file.id,
            type,
            encryptedData,
            decryptionHeader,
        }),
    });
    ensureOk(res);
};
