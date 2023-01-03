export interface MagicMetadataCore {
    version: number;
    count: number;
    header: string;
    data: Record<string, any>;
}

export interface EncryptedMagicMetadata
    extends Omit<MagicMetadataCore, 'data'> {
    data: string;
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
    uploaderName?: string;
}

export interface FilePublicMagicMetadata
    extends Omit<MagicMetadataCore, 'data'> {
    data: FilePublicMagicMetadataProps;
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
    version: 1,
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
    magicMetadata: EncryptedMagicMetadata;
}
