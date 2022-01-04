import { DataStream, MetadataObject } from 'types/upload';

export interface fileAttribute {
    encryptedData?: DataStream | Uint8Array;
    objectKey?: string;
    decryptionHeader: string;
}

export enum FILE_TYPE {
    IMAGE,
    VIDEO,
    LIVE_PHOTO,
    OTHERS,
}

export enum VISIBILITY_STATE {
    VISIBLE,
    ARCHIVED,
}

export interface MagicMetadataCore {
    version: number;
    count: number;
    header: string;
    data: Record<string, any>;
}

export interface EncryptedMagicMetadataCore
    extends Omit<MagicMetadataCore, 'data'> {
    data: string;
}

export interface MagicMetadataProps {
    visibility?: VISIBILITY_STATE;
}

export interface MagicMetadata extends Omit<MagicMetadataCore, 'data'> {
    data: MagicMetadataProps;
}

export interface PublicMagicMetadataProps {
    editedTime?: number;
    editedName?: string;
}

export interface PublicMagicMetadata extends Omit<MagicMetadataCore, 'data'> {
    data: PublicMagicMetadataProps;
}

export interface EnteFile {
    id: number;
    collectionID: number;
    ownerID: number;
    file: fileAttribute;
    thumbnail: fileAttribute;
    metadata: MetadataObject;
    magicMetadata: MagicMetadata;
    pubMagicMetadata: PublicMagicMetadata;
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
