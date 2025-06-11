import {
    type EncryptedMagicMetadata,
    type MagicMetadataCore,
} from "ente-media/file";
import { ItemVisibility } from "ente-media/file-metadata";
import { z } from "zod/v4";

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
 *   [Note: Collection File]), but it must belong to at least one collection.
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
     * - The email is present for the {@link owner} only for shared collections.
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
 */
// TODO: Use me.
export const RemoteCollectionUser = z.looseObject({
    id: z.number(),
    email: z.string().nullish(),
    role: z.string().nullish(),
});

type RemoteCollectionUser = z.infer<typeof RemoteCollectionUser>;

/**
 * Zod schema for {@link Collection}.
 *
 * [Note: Schema validation for bulk persisted remote objects]
 *
 * Objects like files and collections that we get from remote are treated
 * specially when it comes to schema validation.
 *
 * 1. Enum conversion.
 * 2. Loose objects.
 * 3. Blank handling.
 * 4. Casting instead of validating when reading local values.
 *
 * Let us take a concrete example of the {@link Collection} TypeScript type,
 * whose zod schema is defined by {@link RemoteCollection}.
 *
 * The collection that we get from remote contains (nested) enum types - a
 * {@link CollectionParticipantRole}. While zod allows us to validate enum types
 * during a parse, this would cause existing clients to break if remote were to
 * in the future add new enum cases. So when parsing we'd like to keep the role
 * value as a string.
 *
 * This is especially important for a object like {@link Collection} which is
 * also persisted locally, because a current client code might persist a object
 * which might be read by future client code that understands more fields. So we
 * use zod's {@link looseObject} directive on the {@link RemoteCollection} to
 * ensure we don't discard fields we don't recognize, in a manner similar to
 * [Note: Use looseObject for metadata Zod schemas].
 *
 * In keeping with this general principle of retaining the object we get from
 * remote as vintage as possible, we also don't do transformations to deal with
 * various remote idiosyncracies. For example, for the role field remote (in
 * some cases) uses blanks to indicate missing values. While zod would allow to
 * transform these, we just let it be as remote had sent it.
 *
 * Finally, while we always use the {@link RemoteCollection} schema validator
 * when parsing remote network responses, we don't do the same when reading the
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
 * To summarize, for certain remote objects which are also persisted to disk in
 * potentially large numbers, we (a) try to retain the remote semantics as much
 * as possible to avoid the need for a parsing / transform step, and (b) we
 * don't even do a parsing / transform step when reading them from local DB.
 *
 * This means that the "types might lie". On the other hand, we need to special
 * case only very specific objects this way:
 *
 * 1. {@link EnteFile}
 * 2. {@link Collection}
 * 3. {@link Trash}
 *
 */
// TODO: Use me
export const RemoteCollection = z.looseObject({});

export interface EncryptedCollection {
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
     */
    owner: CollectionUser;
    // collection name was unencrypted in the past, so we need to keep it as optional
    name?: string;
    encryptedKey: string;
    keyDecryptionNonce: string;
    encryptedName: string;
    nameDecryptionNonce: string;
    type: CollectionType;
    attributes: collectionAttributes;
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

export interface collectionAttributes {
    encryptedPath?: string;
    pathDecryptionNonce?: string;
}

export interface RemoveFromCollectionRequest {
    collectionID: number;
    fileIDs: number[];
}

export const CollectionSubType = {
    default: 0,
    defaultHidden: 1,
    quicklink: 2,
} as const;

export type CollectionSubType =
    (typeof CollectionSubType)[keyof typeof CollectionSubType];

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
