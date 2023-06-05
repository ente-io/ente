import {
    EncryptedMagicMetadata,
    FileMagicMetadata,
    FilePublicMagicMetadata,
} from 'types/magicMetadata';
import { Metadata } from 'types/upload';

export interface MetadataFileAttributes {
    encryptedData: string;
    decryptionHeader: string;
}
export interface S3FileAttributes {
    objectKey: string;
    decryptionHeader: string;
}

export interface FileInfo {
    fileSize: number;
    thumbSize: number;
}

export interface EncryptedEnteFile {
    id: number;
    collectionID: number;
    ownerID: number;
    file: S3FileAttributes;
    thumbnail: S3FileAttributes;
    metadata: MetadataFileAttributes;
    info: FileInfo;
    magicMetadata: EncryptedMagicMetadata;
    pubMagicMetadata: EncryptedMagicMetadata;
    encryptedKey: string;
    keyDecryptionNonce: string;
    isDeleted: boolean;
    updationTime: number;
}

export interface EnteFile
    extends Omit<
        EncryptedEnteFile,
        | 'metadata'
        | 'pubMagicMetadata'
        | 'magicMetadata'
        | 'encryptedKey'
        | 'keyDecryptionNonce'
    > {
    metadata: Metadata;
    magicMetadata: FileMagicMetadata;
    pubMagicMetadata: FilePublicMagicMetadata;
    isTrashed?: boolean;
    key: string;
    src?: string;
    msrc?: string;
    html?: string;
    w?: number;
    h?: number;
    title?: string;
    deleteBy?: number;
    isSourceLoaded?: boolean;
    originalVideoURL?: string;
    originalImageURL?: string;
    dataIndex?: number;
    conversionFailed?: boolean;
}

export interface TrashRequest {
    items: TrashRequestItems[];
}

export interface TrashRequestItems {
    fileID: number;
    collectionID: number;
}

export interface FileWithUpdatedMagicMetadata {
    file: EnteFile;
    updatedMagicMetadata: FileMagicMetadata;
}

export interface FileWithUpdatedPublicMagicMetadata {
    file: EnteFile;
    updatedPublicMagicMetadata: FilePublicMagicMetadata;
}
