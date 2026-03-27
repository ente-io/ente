import {
    authenticatedPublicAlbumsRequestHeaders,
    authenticatedRequestHeaders,
    ensureOk,
    type PublicAlbumsCredentials,
} from "ente-base/http";
import { apiURL } from "ente-base/origins";
import { nullToUndefined } from "ente-utils/transform";
import { z } from "zod";

/**
 * [Note: File data APIs]
 *
 * Remote provides some APIs that talk in terms of "file data", which refers to
 * all the files (original or derived) associated with an {@link EnteFile}.
 *
 * For example, for each original image that the user uploads, there will be an
 * associated thumbnail file, potentially one or more preview files (optimized
 * for size or compatibility across devices), and possibly more such files in
 * the future.
 *
 * There are specialized APIs for fetching and uploading the originals and the
 * thumbnails. But for the other associated data, we can use the file data APIs.
 */
type FileDataType = "vid_preview" /* See: [Note: Video playlist and preview] */;

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
    /**
     * The epoch microseconds when this file data entry was last upserted.
     * Optional for compatibility with older museum responses.
     */
    updatedAt: z.number().nullish().transform(nullToUndefined),
});

type RemoteFileData = z.infer<typeof RemoteFileData>;

/**
 * Fetch file data of a particular type for a single file.
 *
 * Returns `undefined` if no file data of the given type has been uploaded for
 * this file yet (e.g. if type was "vid_preview", this would indicate that a
 * video preview has been generated for this file yet).
 *
 * @param publicAlbumsCredentials Credentials to use when we are running in the
 * context of the public albums app. If these are not specified, then the
 * credentials of the logged in user are used.
 */
export const fetchFileData = async (
    type: FileDataType,
    fileID: number,
    publicAlbumsCredentials?: PublicAlbumsCredentials,
): Promise<RemoteFileData | undefined> => {
    const params = new URLSearchParams({
        type,
        fileID: fileID.toString(),
        // Ask museum to respond with 204 instead of 404 if no playlist exists
        // for the given file.
        preferNoContent: "true",
    });

    let res: Response;
    if (publicAlbumsCredentials) {
        const url = await apiURL("/public-collection/files/data/fetch");
        const headers = authenticatedPublicAlbumsRequestHeaders(
            publicAlbumsCredentials,
        );
        res = await fetch(`${url}?${params.toString()}`, { headers });
    } else {
        const url = await apiURL("/files/data/fetch");
        res = await fetch(`${url}?${params.toString()}`, {
            headers: await authenticatedRequestHeaders(),
        });
    }

    if (res.status == 204) return undefined;
    // We're passing `preferNoContent` so the expected response is 204, but this
    // might be a self hoster running an older museum that does not recognize
    // that flag, so retain the old behavior. This fallback can be removed in a
    // few months (tag: Migration, note added May 2025).
    if (res.status == 404) return undefined;
    ensureOk(res);
    return z.object({ data: RemoteFileData }).parse(await res.json()).data;
};

/**
 * Fetch the preview file data the given file.
 *
 * @param type The {@link FileDataType} which we want.
 *
 * @param fileIDs The id of the files for which we want the file preview data.
 *
 * @param publicAlbumsCredentials Credentials to use when we are running in the
 * context of the public albums app. If these are not specified, then the
 * credentials of the logged in user are used.
 *
 * @returns the (pre-signed) URL to the preview data, or undefined if there is
 * not preview data of the given type for the given file yet.
 *
 * [Note: File data vs file preview data]
 *
 * In museum's ontology, there is a distinction between two concepts:
 *
 * S3 metadata (museum term, the APIs call it "file data") is data that museum
 * uploads on behalf of the client. e.g.,
 *
 * - Preview video playlist.
 *
 * S3 file data (museum term, the APIs call it "file preview data") is data that
 * a client itself uploads. e.g.,
 *
 * - The preview video itself.
 *
 * - Additional preview images.
 *
 * [Note: Video playlist and preview]
 *
 * For a streaming video, both these concepts are needed:
 *
 * - The encrypted HLS playlist is stored as "file data" of type "vid_preview",
 *
 * - The encrypted video chunks that the playlist refers to are stored as "file
 *   preview data" of type "vid_preview".
 */
export const fetchFilePreviewData = async (
    type: FileDataType,
    fileID: number,
    publicAlbumsCredentials?: PublicAlbumsCredentials,
): Promise<string | undefined> => {
    const params = new URLSearchParams({ type, fileID: fileID.toString() });

    let res: Response;
    if (publicAlbumsCredentials) {
        const headers = authenticatedPublicAlbumsRequestHeaders(
            publicAlbumsCredentials,
        );
        const url = await apiURL("/public-collection/files/data/preview");
        res = await fetch(`${url}?${params.toString()}`, { headers });
    } else {
        const url = await apiURL("/files/data/preview");
        res = await fetch(`${url}?${params.toString()}`, {
            headers: await authenticatedRequestHeaders(),
        });
    }

    if (res.status == 404) return undefined;
    ensureOk(res);
    return z.object({ url: z.string() }).parse(await res.json()).url;
};
