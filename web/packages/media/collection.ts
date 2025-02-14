import {
    type EncryptedMagicMetadata,
    type MagicMetadataCore,
} from "@/media/file";
import { ItemVisibility } from "@/media/file-metadata";

// TODO: Audit this file

export enum CollectionType {
    folder = "folder",
    favorites = "favorites",
    album = "album",
    uncategorized = "uncategorized",
}

export enum COLLECTION_ROLE {
    VIEWER = "VIEWER",
    OWNER = "OWNER",
    COLLABORATOR = "COLLABORATOR",
    UNKNOWN = "UNKNOWN",
}

export interface CollectionUser {
    id: number;
    email: string;
    role: COLLECTION_ROLE;
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

export enum SUB_TYPE {
    DEFAULT = 0,
    DEFAULT_HIDDEN = 1,
    QUICK_LINK_COLLECTION = 2,
}

export interface CollectionMagicMetadataProps {
    visibility?: ItemVisibility;
    subType?: SUB_TYPE;
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
