import {
    type EncryptedMagicMetadata,
    type MagicMetadataCore,
} from "ente-media/file";
import { ItemVisibility } from "ente-media/file-metadata";

// TODO: Audit this file

export type CollectionType = "folder" | "favorites" | "album" | "uncategorized";

export type CollectionRole = "VIEWER" | "OWNER" | "COLLABORATOR" | "UNKNOWN";

export interface CollectionUser {
    id: number;
    email: string;
    role: CollectionRole;
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
