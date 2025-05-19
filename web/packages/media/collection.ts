import {
    type EncryptedMagicMetadata,
    type MagicMetadataCore,
} from "ente-media/file";
import { ItemVisibility } from "ente-media/file-metadata";

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
export type CollectionUserRole =
    | "VIEWER"
    | "COLLABORATOR"
    | "OWNER"
    | "UNKNOWN";

/**
 * Information about the user associated with a collection, either as an owner,
 * or as someone with whom the collection has been shared with.
 */
export interface CollectionUser {
    id: number;
    email: string;
    role: CollectionUserRole;
}

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
