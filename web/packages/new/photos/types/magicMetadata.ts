export interface MagicMetadataCore<T> {
    version: number;
    count: number;
    header: string;
    data: T;
}

export type EncryptedMagicMetadata = MagicMetadataCore<string>;

/**
 * The visibility of an Ente file or collection.
 */
export enum ItemVisibility {
    /** The normal state - The item is visible. */
    visible = 0,
    /** The item has been archived. */
    archived = 1,
    /** The item has been hidden. */
    hidden = 2,
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
