export interface MagicMetadataCore {
    version: number;
    count: number;
    header: string;
    data: Record<string, any>;
}

export enum VISIBILITY_STATE {
    VISIBLE,
    ARCHIVED,
}
