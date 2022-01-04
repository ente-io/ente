import { User } from 'services/userService';
import { EnteFile } from 'types/file';

export enum CollectionType {
    folder = 'folder',
    favorites = 'favorites',
    album = 'album',
}

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

export enum COLLECTION_SORT_BY {
    LATEST_FILE,
    MODIFICATION_TIME,
    NAME,
}

export interface RemoveFromCollectionRequest {
    collectionID: number;
    fileIDs: number[];
}
