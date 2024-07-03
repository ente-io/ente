import { EnteFile } from "@/new/photos/types/file";
import {
    EncryptedMagicMetadata,
    MagicMetadataCore,
    SUB_TYPE,
    VISIBILITY_STATE,
} from "@/new/photos/types/magicMetadata";
import { CollectionSummaryType, CollectionType } from "constants/collection";

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

export interface EncryptedFileKey {
    id: number;
    encryptedKey: string;
    keyDecryptionNonce: string;
}

export interface AddToCollectionRequest {
    collectionID: number;
    files: EncryptedFileKey[];
}

export interface MoveToCollectionRequest {
    fromCollectionID: number;
    toCollectionID: number;
    files: EncryptedFileKey[];
}

export interface collectionAttributes {
    encryptedPath?: string;
    pathDecryptionNonce?: string;
}

export type CollectionToFileMap = Map<number, EnteFile>;

export interface RemoveFromCollectionRequest {
    collectionID: number;
    fileIDs: number[];
}

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

export interface CollectionSummary {
    id: number;
    name: string;
    type: CollectionSummaryType;
    coverFile: EnteFile;
    latestFile: EnteFile;
    fileCount: number;
    updationTime: number;
    order?: number;
}

export type CollectionSummaries = Map<number, CollectionSummary>;
export type CollectionFilesCount = Map<number, number>;
