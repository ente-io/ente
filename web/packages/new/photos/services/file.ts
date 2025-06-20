import { authenticatedRequestHeaders, ensureOk } from "ente-base/http";
import { apiURL } from "ente-base/origins";
import type { EnteFile, EnteFile2 } from "ente-media/file";
import type {
    FilePrivateMagicMetadataData,
    ItemVisibility,
} from "ente-media/file-metadata";
import {
    createMagicMetadata,
    encryptMagicMetadata,
    type RemoteMagicMetadata,
} from "ente-media/magic-metadata";

/**
 * Change the visibility (normal, archived, hidden) of a list of files on
 * remote.
 *
 * Remote only, does not modify local state.
 *
 * @param files The list of files whose visibility we want to change. All the
 * files will get their visibility updated to the new, provided, value.
 *
 * @param visibility The new visibility (normal, archived, hidden).
 */
export const updateFilesVisibility = async (
    files: EnteFile[],
    visibility: ItemVisibility,
) => updateFilesPrivateMagicMetadata(files, { visibility });

/**
 * Update the private magic metadata of a list of files on remote.
 *
 * Remote only, does not modify local state.
 *
 * @param file The list of files whose magic metadata we want to update. The
 * same updates will be applied to the magic metadata of all the files.
 *
 * The existing magic metadata of the provided files is used both to obtain the
 * current magic metadata version, and the existing contents on top of which the
 * updates are applied, so it is imperative that both these values are up to
 * sync with remote otherwise the update will fail.
 *
 * @param updates A non-empty subset of {@link FilePrivateMagicMetadataData}
 * entries.
 *
 * See: [Note: Magic metadata data cannot have nullish values]
 */
const updateFilesPrivateMagicMetadata = async (
    files: EnteFile2[],
    updates: FilePrivateMagicMetadataData,
) =>
    putFilesMagicMetadata({
        metadataList: await Promise.all(
            files.map(async ({ id, key, magicMetadata }) => ({
                id,
                magicMetadata: await encryptMagicMetadata(
                    createMagicMetadata(
                        { ...magicMetadata?.data, ...updates },
                        magicMetadata?.version,
                    ),
                    key,
                ),
            })),
        ),
    });

/**
 * The payload of the remote requests for updating the magic metadata of a
 * single item (file or collection).
 */
export interface UpdateMagicMetadataRequest {
    /**
     * File or collection ID
     */
    id: number;
    /**
     * The updated magic metadata.
     *
     * Remote usually enforces the following constraints when we're trying to
     * update already existing data.
     *
     * - The version should be same as the existing version.
     * - The count should be greater than or equal to the existing count.
     */
    magicMetadata: RemoteMagicMetadata;
}

/**
 * The payload of the remote requests for updating the magic metadata of a
 * multiple items.
 *
 * Currently this is only used by endpoints that update magic metadata for a
 * list of files.
 */
export interface UpdateMultipleMagicMetadataRequest {
    metadataList: UpdateMagicMetadataRequest[];
}

/**
 * Update the private magic metadata of a list of files on remote.
 */
const putFilesMagicMetadata = async (
    updateRequest: UpdateMultipleMagicMetadataRequest,
) =>
    ensureOk(
        await fetch(await apiURL("/files/magic-metadata"), {
            method: "PUT",
            headers: await authenticatedRequestHeaders(),
            body: JSON.stringify(updateRequest),
        }),
    );
