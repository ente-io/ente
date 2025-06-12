import { decryptBoxBytes } from "ente-base/crypto";
import {
    type EncryptedMagicMetadata,
    type MagicMetadataCore,
} from "ente-media/file";
import { ItemVisibility } from "ente-media/file-metadata";
import { nullToUndefined } from "ente-utils/transform";
import { z } from "zod/v4";
import {
    decryptMagicMetadata,
    RemoteMagicMetadataSchema,
    type RemoteMagicMetadata,
} from "./magic-metadata";

// TODO: Audit this file

/**
 * The type of a collection.
 *
 * - "album" - A regular "Ente Album" that the user sees in their library.
 *
 * - "folder" - An Ente Album that is also associated with an OS album on the
 *   user's mobile device.
 *
 *   A collection of type "folder" is created by the mobile app if there is an
 *   associated on-device album for the new Ente album being created.
 *
 *   This separation between "album" and "folder" allows different mobile
 *   clients to push to the same Folder ("Camera", "Screenshots"), not allowing
 *   for duplicate folders with the same name, while still allowing users to
 *   create different albums with the same name.
 *
 *   The web/desktop app does not create collections of type "folder", and
 *   otherwise treats them as aliases for "album".
 *
 * - "favorites" - A special collection consisting of the items that the user
 *   has marked as their favorites.
 *
 *   The user can have at most one collection of type "favorites" (enforced at
 *   remote). This collection is created on demand by the client where the user
 *   first marks an item as a favorite. The user can choose to share their
 *   "favorites" with other users, so it is possible for there to be multiple
 *   collections of type "favorites" present in our local database, however only
 *   one of those will belong to the logged in user (cf `owner.id`).
 *
 * - "uncategorized" - A special collection consisting of items that do not
 *   belong to any other collection.
 *
 *   In the remote schema, each item ({@link EnteFile}) is always associated
 *   with a collection. The same item may belong to multiple collections (See:
 *   [Note: Collection file]), but it must belong to at least one collection.
 *
 *   In some scenarios, e.g. when deleting the last collection to which a file
 *   belongs, the file would thus get orphaned and violate the schema
 *   invariants. So in such cases, the client which is performing the
 *   corresponding operation moves the file to the user's special
 *   "uncategorized" collection, creating it if needed.
 *
 *   Similar to "favorites", the user can have only one "uncategorized"
 *   collection. However, unlike "favorites", the "uncategorized" collection
 *   cannot be shared.
 */
export type CollectionType = "album" | "folder" | "favorites" | "uncategorized";

/**
 * The privilege level of a participant associated with a collection.
 *
 * - "VIEWER" - Has read-only access to files in the collection.
 *
 * - "COLLABORATOR" - Can additionally add files from the collection, and remove
 *   files that they added from the collection (i.e., files they "own").
 *
 * - "OWNER" - The owner of the collection. Can remove any file, including those
 *   added by other users, from the collection.
 *
 * It is guaranteed that a there will be exactly one participant of type OWNER,
 * and their user ID will be the same as the collection `owner.id`.
 */
export type CollectionParticipantRole =
    | "VIEWER"
    | "COLLABORATOR"
    | "OWNER"
    | "UNKNOWN";

/**
 * A subset of {@link CollectionParticipantRole} that are applicable when
 * sharing a collection with another Ente user.
 */
export type CollectionNewParticipantRole = "VIEWER" | "COLLABORATOR";

/**
 * Information about the user associated with a collection, either as an owner,
 * or as someone with whom the collection has been shared with.
 */
export interface CollectionUser {
    /**
     * The ID of the underlying {@link User} that this {@link CollectionUser}
     * stands for.
     */
    id: number;
    /**
     * The email of the user.
     *
     * - The email is present for the {@link owner} only for shared collections
     *   that do not belong to the current user.
     * - The email is present for all {@link sharees}.
     * - Remote uses a blank string to indicate absent values.
     */
    email?: string;
    /**
     * The association / privilege level of the user with the collection.
     *
     * Expected to be one of {@link CollectionParticipantRole}.
     *
     * - The role is not present (blank string) for the {@link owner}.
     * - The role is present, and one of "VIEWER" and "COLLABORATOR" for the
     *   {@link sharees}.
     * - Remote uses a blank string to indicate absent values.
     */
    role?: string;
}

/**
 * Zod schema for {@link CollectionUser}.
 *
 * [Note: Enums in remote objects]
 *
 * In some cases remote returns a value which is part of a known set. The
 * underlying type might be an integer or a string.
 *
 * While Zod allows us to validate enum types during a parse, we refrain from
 * doing this as this would cause existing clients to break if remote were to in
 * the future add new enum cases.
 *
 * This is especially pertinent for objects which we might persist locally,
 * since the client code which persists the object might not know about a
 * particular enum case but a future client which reads the saved value might.
 *
 * So we keep the underlying data type (string or number) as it is instead of
 * converting / validating to an enum or discarding unknown values.
 *
 * As an example consider the {@link role} item in {@link RemoteCollectionUser}.
 * There is a known set of values ({@link CollectionParticipantRole}) this can
 * be, but in the Zod schema we keep the data type as a string.
 */
export const RemoteCollectionUser = z.object({
    id: z.number(),
    email: z.string().nullish().transform(nullToUndefined),
    role: z.string().nullish().transform(nullToUndefined),
});

type RemoteCollectionUser = z.infer<typeof RemoteCollectionUser>;

/**
 * Zod schema for {@link Collection}.
 *
 * See: [Note: Schema suffix for exported Zod schemas].
 *
 * TODO(RE): The following reasoning is not fully correct, since we anyways need
 * to do a conversion when decrypting the collection's fields. The intent is to
 * update this once we've figured out something that also works with the current
 * persistence mechanism (trying to avoid a migration).
 *
 * [Note: Schema validation for bulk persisted remote objects]
 *
 * Objects like files and collections that we get from remote are treated
 * specially when it comes to schema validation.
 *
 * 4. Casting instead of validating when reading local values.
 *
 * Let us take a concrete example of the {@link Collection} TypeScript type,
 * whose zod schema is defined by {@link RemoteCollection}.
 *
 * While we always use the {@link RemoteCollection} schema validator when
 * parsing remote network responses, we don't do the same when reading the
 * persisted values. This is to retain the performance characteristics of the
 * existing code. This might seem miniscule for the {@link Collection} example,
 * but users can easily have hundreds of thousands of {@link EnteFile}s
 * persisted locally, and while the overhead of validation when reading from DB
 * might not matter, but it needs to be profiled first before adding it to the
 * existing code paths.
 *
 * So when reading arrays of these objects from local DB, we do a cast instead
 * of do a runtime zod validation.
 *
 * This means that the "types might lie". On the other hand, we need to special
 * case only very specific objects this way:
 *
 * 1. {@link EnteFile}
 * 2. {@link Collection}
 * 3. {@link Trash}
 *
 */
export const RemoteCollectionSchema = z.object({
    id: z.number(),
    owner: RemoteCollectionUser,
    encryptedKey: z.string(),
    keyDecryptionNonce: z.string(),
    /**
     * Not used anymore, but still might be present for very old collections.
     *
     * Before public launch, collection names were stored unencrypted. For
     * backward compatibility, client should use {@link name} if present,
     * otherwise obtain it by decrypting it from {@link encryptedName} and
     * {@link nameDecryptionNonce}.
     */
    name: z.string().nullish().transform(nullToUndefined),
    /**
     * Expected to be present (along with {@link nameDecryptionNonce}), but it
     * is still optional since it might not be present if {@link name} is present.
     */
    encryptedName: z.string().nullish().transform(nullToUndefined),
    nameDecryptionNonce: z.string().nullish().transform(nullToUndefined),
    /* Expected to be one of {@link CollectionType} */
    type: z.string(),
    // TODO(RE): Use nullishToEmpty?
    sharees: z.array(RemoteCollectionUser).nullish().transform(nullToUndefined), // ?
    // TODO(RE): Use nullishToEmpty?
    publicURLs: z.array(z.looseObject({})).nullish().transform(nullToUndefined), // ?
    updationTime: z.number(),
    /**
     * Tombstone marker.
     *
     * This is set to true in the diff response to indicate collections which
     * have been deleted and should thus be pruned by the client locally.
     */
    isDeleted: z.boolean().nullish().transform(nullToUndefined),
    magicMetadata:
        RemoteMagicMetadataSchema.nullish().transform(nullToUndefined),
    pubMagicMetadata:
        RemoteMagicMetadataSchema.nullish().transform(nullToUndefined),
    sharedMagicMetadata:
        RemoteMagicMetadataSchema.nullish().transform(nullToUndefined),
});

export type RemoteCollection = z.infer<typeof RemoteCollectionSchema>;

export interface EncryptedCollection {
    id: number;
    owner: CollectionUser;
    encryptedKey: string;
    keyDecryptionNonce: string;
    name?: string;
    encryptedName: string;
    nameDecryptionNonce: string;
    type: CollectionType;
    attributes: unknown;
    sharees: CollectionUser[];
    publicURLs?: PublicURL[];
    updationTime: number;
    isDeleted: boolean;
    magicMetadata: EncryptedMagicMetadata;
    pubMagicMetadata: EncryptedMagicMetadata;
    sharedMagicMetadata: EncryptedMagicMetadata;
}

export interface Collection
    extends Omit<
        EncryptedCollection,
        | "encryptedKey"
        | "keyDecryptionNonce"
        | "encryptedName"
        | "nameDecryptionNonce"
        | "magicMetadata"
        | "pubMagicMetadata"
        | "sharedMagicMetadata"
    > {
    key: string;
    name: string;
    magicMetadata: CollectionMagicMetadata;
    pubMagicMetadata: CollectionPublicMagicMetadata;
    sharedMagicMetadata: CollectionShareeMagicMetadata;
}

/**
 * A collection, as used and persisted locally by the client.
 *
 * A collection is roughly equivalent to an "album", though there can be special
 * type of collections (like "favorites") which have special behaviours attached
 * to them.
 *
 * A collection contains zero or more files ({@link EnteFile}).
 *
 * A collection can be owned by the user (in whose context this code is
 * running), or might be a collection that is shared with them.
 *
 * TODO: This type supercedes {@link Collection}. Once migration is done, rename
 * this to drop the "2" suffix.
 */
export interface Collection2 {
    /**
     * The collection's globally unique ID.
     *
     * The collection's ID is a integer assigned by remote as the identifier for
     * an {@link Collection} when it is created. It is globally unique across
     * all collections on an Ente instance (i.e., it is not scoped to a user).
     */
    id: number;
    /**
     * Information about the user who owns the collection.
     *
     * Each collection is owned by exactly one user. The owner may optionally
     * choose to share it with additional users, granting them varying level of
     * privileges.
     *
     * Within the {@link CollectionUser} instance of the {@link owner} field:
     *
     * - {@link email} will be set only if this is a shared collection that does
     *   not belong to the current user.
     * - {@link role} will be blank.
     */
    owner: CollectionUser;
    /**
     * The "collection key" (base64 encoded).
     *
     * The collection key is used to encrypt and decrypt that files that are
     * associated with the collection. See: [Note: Collection file].
     */
    key: string;
    /**
     * The name of the collection.
     */
    name: string;
    /**
     * The type of the collection.
     *
     * Expected to be one of {@link CollectionType}.
     */
    type: string; // CollectionType;
    /**
     * The other Ente users with whom the collection has been shared with.
     *
     * Within the {@link CollectionUser} instances of the {@link sharee} field:
     *
     * - {@link email} will be set.
     * - {@link role} is expected to be one of "VIEWER" or "COLLABORATOR".
     */
    sharees?: CollectionUser[];
    /**
     * Public links that can be used to access and update the collection.
     */
    publicURLs?: unknown; // PublicURL[];
    /**
     * The last time the collection was updated (epoch microseconds).
     *
     * The collection is considered updated both
     *
     * - When the files associated with it modified (added, removed); and
     * - When the collection's own fields are modified.
     */
    updationTime: number;
    /**
     * Mutable metadata associated with the collection that is only visible to
     * the owner of the collection.
     *
     * See: [Note: Metadatum]
     */
    magicMetadata?: unknown; //CollectionMagicMetadata;
    /**
     * Public mutable metadata associated with the collection that is visible to
     * all users with whom the collection has been shared.
     *
     * See: [Note: Metadatum]
     */
    pubMagicMetadata?: unknown; //CollectionPublicMagicMetadata;
    /**
     * Private mutable metadata associated with the collection that is only
     * visible to the current user, if they're not the owner.
     *
     * This is metadata associated with each "share", and is only visible to
     * (and editable by) the user with which the collection has been shared, not
     * the owner. Each user with whom the collection has been shared gets their
     * own private copy. This allows each user to keep their own metadata
     * associated with a shared album (e.g. archive status).
     *
     * See: [Note: Metadatum]
     */
    sharedMagicMetadata?: unknown; // CollectionShareeMagicMetadata;
}

export interface PublicURL {
    url: string;
    deviceLimit: number;
    validTill: number;
    enableDownload: boolean;
    enableCollect: boolean;
    passwordEnabled: boolean;
    nonce?: string;
    opsLimit?: number;
    memLimit?: number;
}

/**
 * Decrypt a remote collection using the provided {@link collectionKey}.
 *
 * @param collection The remote collection to decrypt.
 *
 * @param collectionKey The base64 encoded key to use for decrypting the various
 * encrypted fields in {@link collection}.
 *
 * @returns A decrypted collection.
 */
export const decryptRemoteCollection = async (
    collection: RemoteCollection,
    collectionKey: string,
): Promise<Collection2> => {
    const { id, owner, type, sharees, publicURLs, updationTime } = collection;

    const name =
        collection.name ??
        new TextDecoder().decode(
            await decryptBoxBytes(
                {
                    encryptedData: collection.encryptedName!,
                    nonce: collection.nameDecryptionNonce!,
                },
                collectionKey,
            ),
        );

    const decryptMM = async (mm: RemoteMagicMetadata | undefined) =>
        mm ? await decryptMagicMetadata(mm, collectionKey) : undefined;

    return {
        id,
        owner,
        key: collectionKey,
        name,
        type,
        sharees,
        publicURLs,
        updationTime,
        magicMetadata: await decryptMM(collection.magicMetadata),
        pubMagicMetadata: await decryptMM(collection.pubMagicMetadata),
        sharedMagicMetadata: await decryptMM(collection.sharedMagicMetadata),
    };
};

/**
 * Additional context stored as part of the collection's magic metadata to
 * augment the {@link type} associated with a {@link Collection}.
 */
export const CollectionSubType = {
    default: 0,
    defaultHidden: 1,
    quicklink: 2,
} as const;

export type CollectionSubType =
    (typeof CollectionSubType)[keyof typeof CollectionSubType];

/**
 * Mutable private metadata associated with an {@link Collection}.
 *
 * - Unlike {@link CollectionPublicMagicMetadataData} this is only available to
 *   the owner of the file.
 *
 * See: [Note: Private magic metadata is called magic metadata on remote]
 */
export interface CollectionPrivateMagicMetadataData {
    /**
     * The (owner specific) visibility of the collection.
     *
     * and independently edit its visibility without revealing their visibility
     * preference to the other people with whom they have shared the file.
     */
    visibility?: ItemVisibility;
    /**
     * The {@link CollectionSubType}, if applicable.
     */
    subType?: CollectionSubType;
    /**
     * An overrride to the sort ordering used for the collection.
     *
     * - For pinned collections, this will be set to `1`. Pinned collections
     *   will be moved to the beginning of the sort order.
     *
     * - Otherwise, the collection is a normal (unpinned) collection, and will
     *   retain its natural sort position.
     */
    order?: number;
}

export interface UpdatePublicURL {
    collectionID: number;
    disablePassword?: boolean;
    enableDownload?: boolean;
    enableCollect?: boolean;
    validTill?: number;
    deviceLimit?: number;
    passHash?: string;
    nonce?: string;
    opsLimit?: number;
    memLimit?: number;
}

export interface CreatePublicAccessTokenRequest {
    collectionID: number;
    validTill?: number;
    deviceLimit?: number;
}

export interface RemoveFromCollectionRequest {
    collectionID: number;
    fileIDs: number[];
}

export interface CollectionMagicMetadataProps {
    visibility?: ItemVisibility;
    subType?: CollectionSubType;
    order?: number;
}

export type CollectionMagicMetadata =
    MagicMetadataCore<CollectionMagicMetadataProps>;

export interface CollectionShareeMetadataProps {
    visibility?: ItemVisibility;
}
export type CollectionShareeMagicMetadata =
    MagicMetadataCore<CollectionShareeMetadataProps>;

export interface CollectionPublicMagicMetadataProps {
    /**
     * If true, then the files within the collection are sorted in ascending
     * order of their time ("Oldest first").
     *
     * The default is desc ("Newest first").
     */
    asc?: boolean;
    coverID?: number;
}

export type CollectionPublicMagicMetadata =
    MagicMetadataCore<CollectionPublicMagicMetadataProps>;
