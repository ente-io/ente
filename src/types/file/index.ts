import { MagicMetadataCore, VISIBILITY_STATE } from 'types/magicMetadata';
import { DataStream, Metadata } from 'types/upload';

export interface fileAttribute {
    encryptedData?: DataStream | Uint8Array;
    objectKey?: string;
    decryptionHeader: string;
}
export interface EncryptedMagicMetadataCore
    extends Omit<MagicMetadataCore, 'data'> {
    data: string;
}

export interface FileMagicMetadataProps {
    visibility?: VISIBILITY_STATE;
}

export interface FileMagicMetadata extends Omit<MagicMetadataCore, 'data'> {
    data: FileMagicMetadataProps;
}

export interface FilePublicMagicMetadataProps {
    editedTime?: number;
    editedName?: string;
}

export interface FilePublicMagicMetadata
    extends Omit<MagicMetadataCore, 'data'> {
    data: FilePublicMagicMetadataProps;
}

export interface EnteFile {
    id: number;
    collectionID: number;
    ownerID: number;
    file: fileAttribute;
    thumbnail: fileAttribute;
    metadata: Metadata;
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
    isDeleted: boolean;
    isTrashed?: boolean;
    deleteBy?: number;
    dataIndex: number;
    updationTime: number;
}

export interface UpdateMagicMetadataRequest {
    metadataList: UpdateMagicMetadata[];
}

export interface UpdateMagicMetadata {
    id: number;
    magicMetadata: EncryptedMagicMetadataCore;
}

export const NEW_MAGIC_METADATA: MagicMetadataCore = {
    version: 0,
    data: {},
    header: null,
    count: 0,
};

export interface TrashRequest {
    items: TrashRequestItems[];
}

export interface TrashRequestItems {
    fileID: number;
    collectionID: number;
}
