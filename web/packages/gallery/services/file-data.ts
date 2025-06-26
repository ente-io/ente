import { encryptBlob } from "ente-base/crypto";
import type { EncryptedBlobB64 } from "ente-base/crypto/types";
import {
    authenticatedPublicAlbumsRequestHeaders,
    authenticatedRequestHeaders,
    ensureOk,
    retryEnsuringHTTPOk,
    type PublicAlbumsCredentials,
} from "ente-base/http";
import { apiURL } from "ente-base/origins";
import type { EnteFile } from "ente-media/file";
import { nullToUndefined } from "ente-utils/transform";
import { z } from "zod/v4";

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
type FileDataType =
    | "mldata" /* See: [Note: "mldata" format] */
    | "vid_preview" /* See: [Note: Video playlist and preview] */;

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
     *
     * [Note: PUT "mldata" version check]
     *
     * When PUT-ting mldata onto remote, the client is expected to pass the
     * updated at of the existing {@link RemoteFileData} which it is updating
     * (this field), or 0 if the client is creating a new entity.
     *
     * This allows remote to detect and reject cases where the client is trying
     * to overwrite a version it hasn't yet pulled.
     *
     * About the optionality of this field: Newer museums are expected to always
     * provide the {@link updatedAt} in the response, but for ease of self
     * hosters we don't take a hard dependency on the latest museum and instead
     * allow this field to be optional. When it is not present, effectively
     * we'll pass 0 as {@link lastUpdatedAt} in the "mldata" PUT API call, but
     * since it's an old museum it'll anyway ignore it.
     *
     * > This note was added May 2025, and the optionality can be removed in a
     * > few months when museums should've updated (tag: Migration).
     */
    updatedAt: z.number().nullish().transform(nullToUndefined),
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
export const fetchFilesData = async (
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
 * A variant of {@link fetchFilesData} that fetches data for a single file.
 *
 * Unlike {@link fetchFilesData}, this uses a HTTP GET request.
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
 * An entry in the response to the `/files/data/status-diff`. The actual
 * structure has more fields, there are just the fields we are interested in.
 */
const RemoteFDStatus = z.object({
    /**
     * The ID of the file whose file data we're querying.
     */
    fileID: z.number(),
    /**
     * Expected to be one of {@link FileDataType}
     */
    type: z.string(),
    /**
     * `true` if the file data has been deleted.
     *
     * This can be true in the in-progress partial deletion case, which the file
     * data deletion has been processed but the file deletion has not yet been
     * processed.
     */
    isDeleted: z.boolean(),
    /**
     * The epoch microseconds when this file data entry was added or updated.
     */
    updatedAt: z.number(),
});

/**
 * A paginated part of the result set sent by remote during
 * {@link syncUpdatedFileDataFileIDs}.
 */
export interface UpdatedFileDataFileIDsPage {
    /**
     * The IDs of files for which a file data entry has been created or updated.
     */
    fileIDs: Set<number>;
    /**
     * The latest updatedAt (epoch microseconds) time obtained from remote in
     * this batch being fetched (from amongst all of the files in the batch, not
     * just those that were filtered to be part of {@link fileIDs}).
     */
    lastUpdatedAt: number;
}

/**
 * Fetch the IDs of files for which new file data entries of the given
 * {@link type} have been created or updated since the given {@link sinceTime}.
 *
 * The interaction with remote is paginated, with the {@link onPage} callback
 * being called as each page of new data is received.
 *
 * @param type The {@link FileDataType} for which we want to check for creation
 * or updates.
 *
 * @param lastUpdatedAt Epoch microseconds. This is used to ask remote to
 * provide us only entries whose {@link updatedAt} is more than the given value.
 * Set this to zero to start from the beginning.
 *
 * @param onPage A callback invoked for each page of results received from
 * remote. It is passed the fileIDs received in the batch under consideration,
 * and the largest of the updated time for all entries (irrespective of
 * {@link type}) in that batch.
 *
 * ----
 *
 * [Note: Pruning stale status-diff entries]
 *
 * Unlike other "diff" APIs, the diff API used here won't return tombstone
 * entries for deleted files. This is not a problem because there are no current
 * cases where existing playlists or ML indexes get deleted (unless the
 * underlying file is deleted). See: [Note: Caching HLS playlist data].
 *
 * Note that the "/files/data/status-diff" includes entries for files that are
 * in trash. This means that, while not a practical problem (because it's just
 * numeric ids), the number of fileIDs we store locally can grow unbounded as
 * files move to trash and then get deleted. So to prune them, we also add a
 * hook to the /trash/v2/diff processing, and prune any locally saved file IDs
 * which have been deleted from trash.
 */
export const syncUpdatedFileDataFileIDs = async (
    type: FileDataType,
    lastUpdatedAt: number,
    onPage: (page: UpdatedFileDataFileIDsPage) => Promise<void>,
): Promise<void> => {
    while (true) {
        const res = await fetch(await apiURL("/files/data/status-diff"), {
            method: "POST",
            headers: await authenticatedRequestHeaders(),
            body: JSON.stringify({ lastUpdatedAt }),
        });
        ensureOk(res);
        const diff = z
            .object({ diff: RemoteFDStatus.array().nullish() })
            .parse(await res.json()).diff;
        if (diff?.length) {
            const fileIDs = new Set<number>();
            for (const fd of diff) {
                lastUpdatedAt = Math.max(lastUpdatedAt, fd.updatedAt);
                // While we could prune isDeleted entries here, we can also rely
                // on the pruning that happens when the trash gets synced. See:
                // [Note: Pruning stale status-diff entries]
                if (fd.type == type && !fd.isDeleted) {
                    fileIDs.add(fd.fileID);
                }
            }
            await onPage({ fileIDs, lastUpdatedAt });
        } else {
            break;
        }
    }
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
 *
 * @param lastUpdatedAt The {@link updatedAt} of the {@link RemoteFileData}
 * which we are updating, or 0 to indicate a new entity.
 */
export const putFileData = async (
    file: EnteFile,
    type: FileDataType,
    data: Uint8Array,
    lastUpdatedAt: number,
) => {
    const { encryptedData, decryptionHeader } = await encryptBlob(
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
            lastUpdatedAt,
        }),
    });
    ensureOk(res);
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
 * - ML data.
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

/**
 * Update the video data associated with the given file to remote.
 *
 * Video data refers to two things:
 *
 * - The encrypted HLS playlist ("file data" of type "vid_preview").
 *
 * - The object ID of an (already uploaded) "file preview data" file containing
 *   the video segments.
 *
 * This function is similar to {@link putFileData}, except it will save (or
 * update) both the playlist, and the reference to its associated segment file,
 * associated with the given {@link file}. The playlist data will be end-to-end
 * encrypted using the given {@link file}'s key before uploading.
 *
 * @param file {@link EnteFile} which this data is associated with.
 *
 * @param encryptedPlaylist The encrypted playlist data (along with the nonce
 * used during encryption).
 *
 * @param objectID Object ID of an already uploaded "file preview data" (see
 * {@link getFilePreviewDataUploadURL}).
 *
 * @param objectSize The size (in bytes) of the file corresponding to
 * {@link objectID}.
 */
export const putVideoData = async (
    file: EnteFile,
    encryptedPlaylist: EncryptedBlobB64,
    objectID: string,
    objectSize: number,
) =>
    retryEnsuringHTTPOk(
        async () =>
            fetch(await apiURL("/files/video-data"), {
                method: "PUT",
                headers: await authenticatedRequestHeaders(),
                body: JSON.stringify({
                    fileID: file.id,
                    objectID,
                    objectSize,
                    playlist: encryptedPlaylist.encryptedData,
                    playlistHeader: encryptedPlaylist.decryptionHeader,
                }),
            }),
        { retryProfile: "background" },
    );
