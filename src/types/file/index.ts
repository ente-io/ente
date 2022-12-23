import {
    EncryptedMagicMetadata,
    FileMagicMetadata,
    FilePublicMagicMetadata,
} from 'types/magicMetadata';
import { Metadata } from 'types/upload';

interface FileAttributesBase {
    decryptionHeader: string;
}

interface MetadataFileAttributes extends FileAttributesBase {
    encryptedData: string;
    objectKey?: string;
}
interface S3FileAttributes extends FileAttributesBase {
    objectKey: string;
    encryptedData?: string;
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
    key: string;
    src?: string;
    msrc?: string;
    html?: string;
    w?: number;
    h?: number;
    title?: string;
    isTrashed?: boolean;
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
