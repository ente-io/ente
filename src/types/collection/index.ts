import { User } from 'types/user';
import { EnteFile } from 'types/file';
import { CollectionType } from 'constants/collection';

export interface Collection {
    id: number;
    owner: User;
    key?: string;
    name?: string;
    encryptedName?: string;
    nameDecryptionNonce?: string;
    type: CollectionType;
    attributes: collectionAttributes;
    sharees: User[];
    updationTime: number;
    encryptedKey: string;
    keyDecryptionNonce: string;
    isDeleted: boolean;
    isSharedCollection?: boolean;
    publicURLs?: PublicURL[];
}

export interface PublicURL {
    url: string;
    deviceLimit: number;
    validTill: number;
}

export interface CreatePublicAccessTokenRequest {
    collectionID: number;
    validTill: number;
    deviceLimit: number;
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

export interface CollectionAndItsLatestFile {
    collection: Collection;
    file: EnteFile;
}

export interface RemoveFromCollectionRequest {
    collectionID: number;
    fileIDs: number[];
}
