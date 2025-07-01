/**
 * @file Public albums app specific files DB. See: [Note: Files DB].
 */

import {
    LocalCollections,
    LocalEnteFiles,
    LocalTimestamp,
    transformFilesIfNeeded,
} from "ente-gallery/services/files-db";
import { type Collection } from "ente-media/collection";
import type { EnteFile } from "ente-media/file";
import localForage from "ente-shared/storage/localForage";
import { nullToUndefined } from "ente-utils/transform";
import { z } from "zod/v4";

/**
 * Return all public collections present in our local database.
 *
 * Use {@link savePublicCollections} to update the database.
 */
export const savedPublicCollections = async (): Promise<Collection[]> =>
    // TODO:
    //
    // See: [Note: strict mode migration]
    //
    // We need to add the cast here, otherwise we get a tsc error when this
    // file is imported in the photos app.
    LocalCollections.parse(
        (await localForage.getItem("public-collections")) ?? [],
    ) as Collection[];

/**
 * Replace the list of public collections stored in our local database.
 *
 * This is the setter corresponding to {@link savedPublicCollections}.
 */
export const savePublicCollections = (collections: Collection[]) =>
    localForage.setItem("public-collections", collections);

const LocalReferralCode = z.string().nullish().transform(nullToUndefined);

/**
 * Return the last saved referral code present in our local database.
 *
 * See: [Note: Public albums referral code]. A few more details specific to the
 * persistence of the referral code:
 *
 * 1. The public albums app persists only the referral code for the latest
 *    public album that was fetched.
 *
 * 2. This saved value can be read by
 *    {@link savedLastPublicCollectionReferralCode}.
 *
 * 3. It gets updated as part of {@link publicAlbumsRemotePull}, which writes
 *    out a new value using {@link saveLastPublicCollectionReferralCode}.
 */
export const savedLastPublicCollectionReferralCode = async () =>
    LocalReferralCode.parse(await localForage.getItem("public-referral-code"));

/**
 * Update the referral code present in our local database.
 *
 * This is the setter corresponding to
 * {@link savedLastPublicCollectionReferralCode}.
 */
export const saveLastPublicCollectionReferralCode = async (
    referralCode: string,
) => {
    await localForage.setItem("public-referral-code", referralCode);
};

const LocalSavedPublicCollectionFilesEntry = z.object({
    /**
     * The collection, identified by its access token.
     *
     * See: [Note: Public album access token]
     */
    collectionUID: z.string(),
    files: LocalEnteFiles,
});

type LocalSavedPublicCollectionFilesEntry = z.infer<
    typeof LocalSavedPublicCollectionFilesEntry
>;

// A purely synactic and local alias to avoid the code from looking scary.
type ES = LocalSavedPublicCollectionFilesEntry[];

/**
 * Return all files for a public collection present in our local database.
 *
 * Use {@link savePublicCollectionFiles} to update the database.
 *
 * @param accessToken The access token that identifies the public album under
 * consideration.
 */
export const savedPublicCollectionFiles = async (
    accessToken: string,
): Promise<EnteFile[]> => {
    // See: [Note: Avoiding Zod parsing for large DB arrays] for why we use an
    // (implied) cast here instead of parsing using the Zod schema.
    const entries = await localForage.getItem<ES>("public-collection-files");
    const entry = (entries ?? []).find((e) => e.collectionUID == accessToken);
    return transformFilesIfNeeded(entry ? entry.files : []);
};

/**
 * Replace the list of files for a public collection in our local database.
 *
 * This is the setter corresponding to {@link savedPublicCollectionFiles}.
 *
 * @param accessToken The access token that identifies the public album under
 * consideration.
 *
 * @param files The files to save.
 */
export const savePublicCollectionFiles = async (
    accessToken: string,
    files: EnteFile[],
): Promise<void> => {
    // See: [Note: Avoiding Zod parsing for large DB arrays].
    const entries = await localForage.getItem<ES>("public-collection-files");
    await localForage.setItem("public-collection-files", [
        { collectionUID: accessToken, files },
        ...(entries ?? []).filter((e) => e.collectionUID != accessToken),
    ]);
};

/**
 * Return the locally persisted "last sync time" for a public collection that we
 * have pulled from remote. This can be used to perform a paginated delta pull
 * from the saved time onwards.
 *
 * Use {@link savePublic CollectionLastSyncTime} to update the value saved in
 * the database, and {@link removePublicCollectionLastSyncTime} to remove the
 * saved value from the database.
 *
 * @param accessToken The access token that identifies the public album under
 * consideration.
 */
export const savedPublicCollectionLastSyncTime = async (accessToken: string) =>
    LocalTimestamp.parse(
        await localForage.getItem(`public-${accessToken}-time`),
    );

/**
 * Update the locally persisted timestamp that will be returned by subsequent
 * calls to {@link savedPublicCollectionLastSyncTime}.
 */
export const savePublicCollectionLastSyncTime = async (
    accessToken: string,
    time: number,
) => {
    await localForage.setItem(`public-${accessToken}-time`, time);
};

/**
 * Remove the locally persisted timestamp, if any, previously saved for a
 * collection using {@link savedPublicCollectionLastSyncTime}.
 */
export const removePublicCollectionLastSyncTime = async (
    accessToken: string,
) => {
    await localForage.removeItem(`public-${accessToken}-time`);
};

const LocalUploaderName = z.string().nullish().transform(nullToUndefined);

/**
 * Return the previously saved uploader name, if any, present in our local
 * database corresponding to a public collection.
 *
 * Use {@link savePublicCollectionUploaderName} to update the persisted value.
 *
 * [Note: Public albums uploader name]
 *
 * Whenever there is an upload to a public album, we ask the person doing the
 * upload for their name. This uploader name is attached as part of the public
 * magic metadata of the file so that other people know who uploaded the file.
 *
 * The public albums app also saves this value, keyed by an identifier for the
 * public collection, in the local database so that it can prefill it the next
 * time there is an upload from the same client.
 *
 * @param accessToken The access token that identifies the public album under
 * consideration.
 */
export const savedPublicCollectionUploaderName = async (accessToken: string) =>
    LocalUploaderName.parse(
        await localForage.getItem(`public-${accessToken}-uploaderName`),
    );

/**
 * Update the uploader name present in our local database corresponding to a
 * public collection.
 *
 * This is the setter corresponding to
 * {@link savedPublicCollectionUploaderName}.
 */
export const savePublicCollectionUploaderName = async (
    accessToken: string,
    uploaderName: string,
) => {
    await localForage.setItem(
        `public-${accessToken}-uploaderName`,
        uploaderName,
    );
};
