import { EnteFile } from "types/file";
import {
    EncryptedMagicMetadata,
    MagicMetadataCore,
    SUB_TYPE,
    VISIBILITY_STATE,
} from "types/magicMetadata";

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

enum CollectionType {
    folder = "folder",
    favorites = "favorites",
    album = "album",
    uncategorized = "uncategorized",
}

export interface EncryptedCollection {
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
    publicURLs?: unknown;
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

// define a method on Collection interface to return the sync key as collection.id-time
// this is used to store the last sync time of a collection in local storage

export interface collectionAttributes {
    encryptedPath?: string;
    pathDecryptionNonce?: string;
}

export type CollectionToFileMap = Map<number, EnteFile>;

export interface CollectionMagicMetadataProps {
    visibility?: VISIBILITY_STATE;
    subType?: SUB_TYPE;
    order?: number;
}

export type CollectionMagicMetadata =
    MagicMetadataCore<CollectionMagicMetadataProps>;

export interface CollectionShareeMetadataProps {
    visibility?: VISIBILITY_STATE;
}
export type CollectionShareeMagicMetadata =
    MagicMetadataCore<CollectionShareeMetadataProps>;

export interface CollectionPublicMagicMetadataProps {
    asc?: boolean;
    coverID?: number;
}

export type CollectionPublicMagicMetadata =
    MagicMetadataCore<CollectionPublicMagicMetadataProps>;

export type CollectionFilesCount = Map<number, number>;
