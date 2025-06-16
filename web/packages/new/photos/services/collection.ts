import { ensureLocalUser, type User } from "ente-accounts/services/user";
import {
    boxSeal,
    boxSealOpen,
    decryptBox,
    encryptBox,
    generateKey,
} from "ente-base/crypto";
import { authenticatedRequestHeaders, ensureOk } from "ente-base/http";
import { apiURL } from "ente-base/origins";
import { ensureMasterKeyFromSession } from "ente-base/session";
import {
    CollectionSubType,
    decryptRemoteCollection,
    RemoteCollection,
    RemotePublicURL,
    type Collection,
    type Collection2,
    type CollectionNewParticipantRole,
    type CollectionPrivateMagicMetadataData,
    type CollectionShareeMagicMetadataData,
    type CollectionType,
    type PublicURL,
} from "ente-media/collection";
import { type EnteFile } from "ente-media/file";
import { ItemVisibility } from "ente-media/file-metadata";
import {
    createMagicMetadata,
    encryptMagicMetadata,
    type RemoteMagicMetadata,
} from "ente-media/magic-metadata";
import { batch } from "ente-utils/array";
import { z } from "zod/v4";
import { ensureUserKeyPair, getPublicKey } from "./user";

/**
 * An reasonable but otherwise arbitrary number of items (e.g. files) to include
 * in a single API request.
 *
 * Remote will reject too big payloads, and requests which affect multiple items
 * (e.g. files when moving files to a collection) are expected to be batched to
 * keep each request of a reasonable size. By default, we break the request into
 * batches of 1000.
 */
const requestBatchSize = 1000;

export const ARCHIVE_SECTION = -1;
export const TRASH_SECTION = -2;
export const DUMMY_UNCATEGORIZED_COLLECTION = -3;
export const HIDDEN_ITEMS_SECTION = -4;
export const ALL_SECTION = 0;

/**
 * Return true if this is a default hidden collection.
 *
 * See also: [Note: Multiple "default" hidden collections].
 */
export const isDefaultHiddenCollection = (collection: Collection) =>
    // TODO: Need to audit the types
    // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
    collection.magicMetadata?.data.subType == CollectionSubType.defaultHidden;

/**
 * Extract the IDs of all the "default" hidden collections.
 *
 * [Note: Multiple "default" hidden collections].
 *
 * Normally, there is only expected to be one such collection. But to provide
 * clients laxity in synchronization, we don't enforce this and instead allow
 * for multiple such default hidden collections to exist.
 */
export const findDefaultHiddenCollectionIDs = (collections: Collection[]) =>
    new Set<number>(
        collections
            .filter(isDefaultHiddenCollection)
            .map((collection) => collection.id),
    );

/**
 * Return true if this is a collection that the user doesn't own.
 */
export const isIncomingShare = (collection: Collection, user: User) =>
    collection.owner.id !== user.id;

export const isHiddenCollection = (collection: Collection) =>
    // TODO: Need to audit the types
    // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
    collection.magicMetadata?.data.visibility === ItemVisibility.hidden;

export const DEFAULT_HIDDEN_COLLECTION_USER_FACING_NAME = "Hidden";

/**
 * Return the "user facing" name of the given collection.
 *
 * Usually this is the same as the collection name, but it might be a different
 * string for special collections like default hidden collections.
 */
export const getCollectionUserFacingName = (collection: Collection) => {
    if (isDefaultHiddenCollection(collection)) {
        return DEFAULT_HIDDEN_COLLECTION_USER_FACING_NAME;
    }
    return collection.name;
};

/**
 * Create a new collection on remote, and return its local representation.
 *
 * Remote only, does not modify local state.
 *
 * @param name The name of the new collection.
 *
 * @param type The type of the new collection.
 *
 * @param magicMetadataData Optional metadata to use as the collection's private
 * mutable metadata when creating the new collection.
 */
export const createCollection2 = async (
    name: string,
    type: CollectionType,
    magicMetadataData?: CollectionPrivateMagicMetadataData,
): Promise<Collection> => {
    const masterKey = await ensureMasterKeyFromSession();
    const collectionKey = await generateKey();
    const { encryptedData: encryptedKey, nonce: keyDecryptionNonce } =
        await encryptBox(collectionKey, masterKey);
    const { encryptedData: encryptedName, nonce: nameDecryptionNonce } =
        await encryptBox(new TextEncoder().encode(name), collectionKey);
    const magicMetadata = magicMetadataData
        ? await encryptMagicMetadata(
              createMagicMetadata(magicMetadataData),
              collectionKey,
          )
        : undefined;

    const collection = await postCollections({
        encryptedKey,
        keyDecryptionNonce,
        encryptedName,
        nameDecryptionNonce,
        type,
        ...(magicMetadata && { magicMetadata }),
    });

    return decryptRemoteCollection(
        collection,
        await decryptCollectionKey(collection),
    );
};

// TODO(C2): Temporary method to convert to the newer type.
export const collection1To2 = async (c1: Collection): Promise<Collection2> => {
    const collection = RemoteCollection.parse({
        ...c1,
        magicMetadata: undefined,
        pubMagicMetadata: undefined,
        sharedMagicMetadata: undefined,
    });
    const c2 = await decryptRemoteCollection(
        collection,
        await decryptCollectionKey(collection),
    );
    return {
        ...c2,
        magicMetadata: c1.magicMetadata,
        pubMagicMetadata: c1.pubMagicMetadata,
        sharedMagicMetadata: c1.sharedMagicMetadata,
    };
};

/**
 * Return the decrypted collection key (as a base64 string) for the given
 * {@link RemoteCollection}.
 */
export const decryptCollectionKey = async (
    collection: RemoteCollection,
): Promise<string> => {
    const { owner, encryptedKey, keyDecryptionNonce } = collection;
    if (owner.id == ensureLocalUser().id) {
        // The collection key of collections owned by the user is encrypted with
        // the user's master key. The nonce will be present in such cases.
        return decryptBox(
            { encryptedData: encryptedKey, nonce: keyDecryptionNonce! },
            await ensureMasterKeyFromSession(),
        );
    } else {
        // The collection key of collections shared with the user is encrypted
        // with the user's public key.
        return boxSealOpen(encryptedKey, await ensureUserKeyPair());
    }
};

/**
 * Create a collection on remote with the provided data, and return the new
 * remote collection object returned by remote on success.
 */
const postCollections = async (
    collectionData: Partial<RemoteCollection>,
): Promise<RemoteCollection> => {
    const res = await fetch(await apiURL("/collections"), {
        method: "POST",
        headers: await authenticatedRequestHeaders(),
        body: JSON.stringify(collectionData),
    });
    ensureOk(res);
    return z.object({ collection: RemoteCollection }).parse(await res.json())
        .collection;
};

/**
 * Return a map of the (user-facing) collection name, indexed by collection ID.
 */
export const createCollectionNameByID = (collections: Collection[]) =>
    new Map(collections.map((c) => [c.id, getCollectionUserFacingName(c)]));

/**
 * A CollectionFileItem represents a file in a API request to add, move or
 * restore files to a particular collection.
 */
interface CollectionFileItem {
    /**
     * The file's ID.
     */
    id: number;
    /**
     * The file's key (as a base64 string), encrypted with the key of the
     * collection to which it is being added or moved.
     */
    encryptedKey: string;
    /**
     * The nonce (as a base64 string) that was used during the encryption of
     * {@link encryptedKey}.
     */
    keyDecryptionNonce: string;
}

export interface AddToCollectionRequest {
    collectionID: number;
    files: CollectionFileItem[];
}

export interface MoveToCollectionRequest {
    fromCollectionID: number;
    toCollectionID: number;
    files: CollectionFileItem[];
}

/**
 * Make a remote request to add the given {@link files} to the given
 * {@link collection}.
 *
 * Remote only, does not modify local state.
 */
export const addToCollection = async (
    collection: Collection,
    files: EnteFile[],
) => {
    for (const batchFiles of batch(files, requestBatchSize)) {
        const encryptedFileKeys = await encryptWithCollectionKey(
            collection,
            batchFiles,
        );
        ensureOk(
            await fetch(await apiURL("/collections/add-files"), {
                method: "POST",
                headers: await authenticatedRequestHeaders(),
                body: JSON.stringify({
                    collectionID: collection.id,
                    files: encryptedFileKeys,
                }),
            }),
        );
    }
};

/**
 * Make a remote request to restore the given {@link files} to the given
 * {@link collection}.
 *
 * Remote only, does not modify local state.
 */
export const restoreToCollection = async (
    collection: Collection,
    files: EnteFile[],
) => {
    for (const batchFiles of batch(files, requestBatchSize)) {
        const encryptedFileKeys = await encryptWithCollectionKey(
            collection,
            batchFiles,
        );
        ensureOk(
            await fetch(await apiURL("/collections/restore-files"), {
                method: "POST",
                headers: await authenticatedRequestHeaders(),
                body: JSON.stringify({
                    collectionID: collection.id,
                    files: encryptedFileKeys,
                }),
            }),
        );
    }
};

/**
 * Make a remote request to move the given {@link files} from a collection (as
 * identified by its {@link fromCollectionID}) to the given
 * {@link toCollection}.
 *
 * Remote only, does not modify local state.
 */
export const moveToCollection = async (
    fromCollectionID: number,
    toCollection: Collection,
    files: EnteFile[],
) => {
    for (const batchFiles of batch(files, requestBatchSize)) {
        const encryptedFileKeys = await encryptWithCollectionKey(
            toCollection,
            batchFiles,
        );
        ensureOk(
            await fetch(await apiURL("/collections/move-files"), {
                method: "POST",
                headers: await authenticatedRequestHeaders(),
                body: JSON.stringify({
                    fromCollectionID: fromCollectionID,
                    toCollectionID: toCollection.id,
                    files: encryptedFileKeys,
                }),
            }),
        );
    }
};

/**
 * Return an array of {@link CollectionFileItem}s, one for each file in
 * {@link files}, containing the corresponding file' ID and keys, but this time
 * encrypted using the key of the given {@link collection}.
 */
const encryptWithCollectionKey = async (
    collection: Collection,
    files: EnteFile[],
): Promise<CollectionFileItem[]> =>
    Promise.all(
        files.map(async (file) => {
            const box = await encryptBox(file.key, collection.key);
            return {
                id: file.id,
                encryptedKey: box.encryptedData,
                keyDecryptionNonce: box.nonce,
            };
        }),
    );

/**
 * Make a remote request to move the given {@link files} to trash.
 *
 * @param files The {@link EnteFile}s to move to trash. The API request needs
 * both a file ID and a collection ID, but there should be at most one entry for
 * a particular fileID in this array.
 *
 * Remote only, does not modify local state.
 */
export const moveToTrash = async (files: EnteFile[]) => {
    for (const batchFiles of batch(files, requestBatchSize)) {
        ensureOk(
            await fetch(await apiURL("/files/trash"), {
                method: "POST",
                headers: await authenticatedRequestHeaders(),
                body: JSON.stringify({
                    items: batchFiles.map((file) => ({
                        fileID: file.id,
                        collectionID: file.collectionID,
                    })),
                }),
            }),
        );
    }
};

/**
 * Make a remote request to delete the given {@link fileIDs} from trash.
 *
 * Remote only, does not modify local state.
 */
export const deleteFromTrash = async (fileIDs: number[]) => {
    for (const batchIDs of batch(fileIDs, requestBatchSize)) {
        ensureOk(
            await fetch(await apiURL("/trash/delete"), {
                method: "POST",
                headers: await authenticatedRequestHeaders(),
                body: JSON.stringify({ fileIDs: batchIDs }),
            }),
        );
    }
};

/**
 * Rename a collection on remote.
 *
 * Remote only, does not modify local state.
 *
 * @param collection The collection to rename.
 *
 * @param newName The new name of the collection
 */
export const renameCollection2 = async (
    collection: Collection2,
    newName: string,
) => {
    if (collection.magicMetadata?.data.subType == CollectionSubType.quicklink) {
        // Convert quicklinks to a regular collection before giving them a name.
        await updateCollectionPrivateMagicMetadata(collection, {
            subType: CollectionSubType.default,
        });
    }
    const { encryptedData: encryptedName, nonce: nameDecryptionNonce } =
        await encryptBox(new TextEncoder().encode(newName), collection.key);
    await postCollectionsRename({
        collectionID: collection.id,
        encryptedName,
        nameDecryptionNonce,
    });
};

interface RenameRequest {
    collectionID: number;
    encryptedName: string;
    nameDecryptionNonce: string;
}

const postCollectionsRename = async (renameRequest: RenameRequest) =>
    ensureOk(
        await fetch(await apiURL("/collections/rename"), {
            method: "POST",
            headers: await authenticatedRequestHeaders(),
            body: JSON.stringify(renameRequest),
        }),
    );

/**
 * Change the visibility (normal, archived, hidden) of a collection on remote.
 *
 * Remote only, does not modify local state.
 *
 * This function works with both collections owned by the user, and collections
 * shared with the user.
 *
 * @param collection The collection whose visibility we want to change.
 *
 * @param visibility The new visibility (normal, archived, hidden).
 */
export const updateCollectionVisibility = async (
    collection: Collection2,
    visibility: ItemVisibility,
) =>
    collection.owner.id == ensureLocalUser().id
        ? updateCollectionPrivateMagicMetadata(collection, { visibility })
        : updateCollectionShareeMagicMetadata(collection, { visibility });

/**
 * Update the private magic metadata contents of a collection on remote.
 *
 * Remote only, does not modify local state.
 *
 * @param collection The collection whose magic metadata we want to update.
 *
 * The existing magic metadata of this collection is used both to obtain the
 * current magic metadata version, and the existing contents on top of which the
 * updates are applied, so it is imperative that both these values are up to
 * sync with remote otherwise the update will fail.
 *
 * @param updates A non-empty subset of
 * {@link CollectionPrivateMagicMetadataData} entries.
 *
 * See: [Note: Magic metadata data cannot have nullish values]
 */
export const updateCollectionPrivateMagicMetadata = async (
    { id, key, magicMetadata }: Collection2,
    updates: CollectionPrivateMagicMetadataData,
) =>
    putCollectionsMagicMetadata({
        id,
        magicMetadata: await encryptMagicMetadata(
            createMagicMetadata(
                { ...magicMetadata?.data, ...updates },
                magicMetadata?.version,
            ),
            key,
        ),
    });

/**
 * The payload of the remote requests for updating the magic metadata of a
 * single collection.
 */
interface UpdateCollectionMagicMetadataRequest {
    /**
     * Collection ID
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
 * Update the private magic metadata of a single collection on remote.
 */
const putCollectionsMagicMetadata = async (
    updateRequest: UpdateCollectionMagicMetadataRequest,
) =>
    ensureOk(
        await fetch(await apiURL("/collections/magic-metadata"), {
            method: "PUT",
            headers: await authenticatedRequestHeaders(),
            body: JSON.stringify(updateRequest),
        }),
    );

/**
 * Update the per-sharee magic metadata contents of a collection on remote.
 *
 * Remote only, does not modify local state.
 *
 * This is a variant of {@link updateCollectionPrivateMagicMetadata} that works
 * with the {@link sharedMagicMetadata} of a collection.
 */
const updateCollectionShareeMagicMetadata = async (
    { id, key, sharedMagicMetadata }: Collection2,
    updates: CollectionShareeMagicMetadataData,
) =>
    putCollectionsShareeMagicMetadata({
        id,
        magicMetadata: await encryptMagicMetadata(
            createMagicMetadata(
                { ...sharedMagicMetadata?.data, ...updates },
                sharedMagicMetadata?.version,
            ),
            key,
        ),
    });

/**
 * Update the sharee magic metadata of a single shared collection on remote.
 */
const putCollectionsShareeMagicMetadata = async (
    updateRequest: UpdateCollectionMagicMetadataRequest,
) =>
    ensureOk(
        await fetch(await apiURL("/collections/sharee-magic-metadata"), {
            method: "PUT",
            headers: await authenticatedRequestHeaders(),
            body: JSON.stringify(updateRequest),
        }),
    );

/**
 * Share the provided collection with another Ente user.
 *
 * Remote only, does not modify local state.
 *
 * @param collection The {@link Collection} to share.
 *
 * @param withUserEmail The email of the Ente user with whom to share it.
 *
 * @param role The desired role for the new participant.
 */
export const shareCollection = async (
    collection: Collection,
    withUserEmail: string,
    role: CollectionNewParticipantRole,
) => {
    const publicKey = await getPublicKey(withUserEmail);
    const encryptedKey = await boxSeal(collection.key, publicKey);

    ensureOk(
        await fetch(await apiURL("/collections/share"), {
            method: "POST",
            headers: await authenticatedRequestHeaders(),
            body: JSON.stringify({
                collectionID: collection.id,
                email: withUserEmail,
                role,
                encryptedKey,
            }),
        }),
    );
};

/**
 * Stop sharing a collection on remote with the given user.
 *
 * Remote only, does not modify local state.
 *
 * @param collectionID The ID of the collection to stop sharing with the user
 * having the given {@link email}.
 *
 * @param email The email of the Ente user with whom to stop sharing.
 */
export const unshareCollection = async (collectionID: number, email: string) =>
    ensureOk(
        await fetch(await apiURL("/collections/unshare"), {
            method: "POST",
            headers: await authenticatedRequestHeaders(),
            body: JSON.stringify({ collectionID, email }),
        }),
    );

/**
 * The subset of public URL attributes that can be customized by the user when
 * creating a link.
 */
export type CreatePublicURLAttributes = Pick<
    Partial<PublicURL>,
    "enableCollect" | "enableJoin" | "validTill" | "deviceLimit"
>;

/**
 * Create a new public link for the given collection.
 *
 * Remote only, does not modify local state.
 *
 * @param collectionID The ID of the collection for which the public link should
 * be created.
 *
 * @param attributes Optional attributes to set when creating the public link.
 */
export const createPublicURL = async (
    collectionID: number,
    attributes?: CreatePublicURLAttributes,
): Promise<PublicURL> => {
    const res = await fetch(await apiURL("/collections/share-url"), {
        method: "POST",
        headers: await authenticatedRequestHeaders(),
        body: JSON.stringify({ collectionID, ...attributes }),
    });
    ensureOk(res);
    // See: [Note: strict mode migration]
    //
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    return z.object({ result: RemotePublicURL }).parse(await res.json()).result;
};

/**
 * The subset of public URL attributes that can be updated by the user after the
 * link has already been created.
 */
export type UpdatePublicURLAttributes = Omit<
    Partial<PublicURL>,
    "url" | "enablePassword"
> & { disablePassword?: boolean; passHash?: string };

/**
 * Update the attributes of an existing public link for a shared collection.
 *
 * Remote only, does not modify local state.
 *
 * @param collectionID The ID of the collection whose public link to update.
 *
 * @param updates The public link attributes to modify. Only attributes
 * corresponding to entries with non nullish values will be updated, all the
 * other existing attributes will remain unmodified.
 *
 * @returns the updated public URL.
 */
export const updatePublicURL = async (
    collectionID: number,
    updates: UpdatePublicURLAttributes,
): Promise<PublicURL> => {
    const res = await fetch(await apiURL("/collections/share-url"), {
        method: "PUT",
        headers: await authenticatedRequestHeaders(),
        body: JSON.stringify({ collectionID, ...updates }),
    });
    ensureOk(res);
    // See: [Note: strict mode migration]
    //
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    return z.object({ result: RemotePublicURL }).parse(await res.json()).result;
};

/**
 * Delete the public link for the collection with given {@link collectionID}.
 *
 * Remote only, does not modify local state.
 */
export const deleteShareURL = async (collectionID: number) =>
    ensureOk(
        await fetch(await apiURL(`/collections/share-url/${collectionID}`), {
            method: "DELETE",
            headers: await authenticatedRequestHeaders(),
        }),
    );

/**
 * Leave a collection which had previously been shared with the user.
 *
 * Remote only, does not modify local state.
 *
 * @param collectionID The ID of the shared collection to leave.
 */
export const leaveSharedCollection = async (collectionID: number) =>
    ensureOk(
        await fetch(await apiURL(`/collections/leave/${collectionID}`), {
            method: "POST",
            headers: await authenticatedRequestHeaders(),
        }),
    );
