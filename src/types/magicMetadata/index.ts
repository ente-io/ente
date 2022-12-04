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

export enum VISIBILITY_STATE {
    VISIBLE = 0,
    ARCHIVED = 1,
    HIDDEN = 2,
}

export enum SUB_TYPE {
    DEFAULT_HIDDEN = 1,
}

export const NEW_FILE_MAGIC_METADATA: MagicMetadataCore = {
    version: 0,
    data: {},
    header: null,
    count: 0,
};

export const NEW_COLLECTION_MAGIC_METADATA: MagicMetadataCore = {
    version: 1,
    data: {},
    header: null,
    count: 0,
};

export interface BulkUpdateMagicMetadataRequest {
    metadataList: UpdateMagicMetadataRequest[];
}

export interface UpdateMagicMetadataRequest {
    id: number;
    magicMetadata: EncryptedMagicMetadataCore;
}
