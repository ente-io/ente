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
    VISIBLE,
    ARCHIVED,
}

export const NEW_MAGIC_METADATA: MagicMetadataCore = {
    version: 0,
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
