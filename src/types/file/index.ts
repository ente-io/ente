import { MagicMetadataCore, VISIBILITY_STATE } from 'types/magicMetadata';
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
    uploaderName?: string;
}

export interface FilePublicMagicMetadata
    extends Omit<MagicMetadataCore, 'data'> {
    data: FilePublicMagicMetadataProps;
}

export interface EnteFileInfo {
    fileSize: number;
    thumbSize: number;
}

export interface EnteFile {
    id: number;
    collectionID: number;
    ownerID: number;
    file: FileAttributes;
    thumbnail: FileAttributes;
    metadata: Metadata;
    info: EnteFileInfo;
    magicMetadata: FileMagicMetadata;
    pubMagicMetadata: FilePublicMagicMetadata;
    encryptedKey: string;
    keyDecryptionNonce: string;
    key: string;
    src: string;
    msrc: string;
    html: string;
    w: number;
    h: number;
    title: string;
    isDeleted: boolean;
    isTrashed?: boolean;
    deleteBy?: number;
    isSourceLoaded?: boolean;
    originalVideoURL?: string;
    originalImageURL?: string;
    dataIndex: number;
    updationTime: number;
}

export interface TrashRequest {
    items: TrashRequestItems[];
}

export interface TrashRequestItems {
    fileID: number;
    collectionID: number;
}
