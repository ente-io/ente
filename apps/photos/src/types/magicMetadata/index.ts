export interface MagicMetadataCore<T> {
    version: number;
    count: number;
    header: string;
    data: T;
}

export type EncryptedMagicMetadata = MagicMetadataCore<string>;

export enum VISIBILITY_STATE {
    VISIBLE = 0,
    ARCHIVED = 1,
    HIDDEN = 2,
}

export enum SUB_TYPE {
    DEFAULT = 0,
    DEFAULT_HIDDEN = 1,
    QUICK_LINK_COLLECTION = 2,
}

export interface BulkUpdateMagicMetadataRequest {
    metadataList: UpdateMagicMetadataRequest[];
}

export interface UpdateMagicMetadataRequest {
    id: number;
    magicMetadata: EncryptedMagicMetadata;
}
