import {
    EncryptedMagicMetadata,
    FileMagicMetadata,
    FilePublicMagicMetadata,
} from 'types/magicMetadata';
import { Metadata } from 'types/upload';

interface MetadataFileAttributes {
    encryptedData: string;
    decryptionHeader: string;
    objectKey?: string;
}
interface S3FileAttributes {
    objectKey: string;
    encryptedData?: string;
    decryptionHeader: string;
}

export type FileAttributes = MetadataFileAttributes | S3FileAttributes;

export interface FileInfo {
    fileSize: number;
    thumbSize: number;
}

export interface EncryptedEnteFile {
    id: number;
    collectionID: number;
    ownerID: number;
    file: FileAttributes;
    thumbnail: FileAttributes;
    metadata: FileAttributes;
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
}

export interface TrashRequest {
    items: TrashRequestItems[];
}

export interface TrashRequestItems {
    fileID: number;
    collectionID: number;
}
