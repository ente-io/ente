import {
    EncryptedMagicMetadata,
    MagicMetadataCore,
    VISIBILITY_STATE,
} from 'types/magicMetadata';
import { DataStream, Metadata } from 'types/upload';

export interface FileAttribute {
    encryptedData: DataStream | Uint8Array;
    decryptionHeader: string;
}

export interface B64FileAttribute {
    encryptedData: string;
    decryptionHeader: string;
}

export interface S3FileAttribute {
    objectKey: string;
    decryptionHeader: string;
}

export interface EnteFileInfo {
    fileSize: number;
    thumbSize: number;
}

export interface EncryptedEnteFile {
    id: number;
    collectionID: number;
    ownerID: number;
    file: S3FileAttribute;
    thumbnail: S3FileAttribute;
    metadata: B64FileAttribute;
    info: EnteFileInfo;
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

export interface FileMagicMetadataProps {
    visibility?: VISIBILITY_STATE;
    filePaths?: string[];
}

export interface FileMagicMetadata extends Omit<MagicMetadataCore, 'data'> {
    data: FileMagicMetadataProps;
}

export interface FilePublicMagicMetadataProps {
    editedTime?: number;
    editedName?: string;
    caption?: string;
}

export interface FilePublicMagicMetadata
    extends Omit<MagicMetadataCore, 'data'> {
    data: FilePublicMagicMetadataProps;
}

export interface TrashRequest {
    items: TrashRequestItems[];
}

export interface TrashRequestItems {
    fileID: number;
    collectionID: number;
}
