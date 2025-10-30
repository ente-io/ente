export interface FileLinkInfo {
    file?: {
        id?: number;
        ownerID?: number;
        collectionID?: number;
        encryptedKey?: string;
        keyDecryptionNonce?: string;
        file?: { decryptionHeader?: string; size?: number };
        thumbnail?: { decryptionHeader?: string; size?: number };
        metadata?: {
            encryptedData?: string;
            decryptionHeader?: string;
            size?: number;
        };
        info?: { fileSize?: number; thumbSize?: number };
        isDeleted?: boolean;
        updationTime?: number;
        pubMagicMetadata?: {
            version?: number;
            count?: number;
            data?: string;
            header?: string;
        };
        // Legacy field names
        encryptedMetadata?: string;
        metadataDecryptionHeader?: string;
        fileSize?: number;
        uploadedTime?: number;
    };
    ownerName?: string;
}

export interface LockerInfoData {
    content?: string;
    location?: string;
    notes?: string;
    username?: string;
    password?: string;
    contactDetails?: string;
    size?: number;
}

export interface LockerInfo {
    type?: string;
    data?: LockerInfoData;
}

export interface FileMetadata {
    fileName?: string;
    title?: string;
    name?: string;
    fileSize?: number;
    size?: number;
    uploadedTime?: number;
    createdAt?: number;
    modificationTime?: number;
}

export interface DecryptedFileInfo {
    id: number;
    fileName: string;
    fileSize: number;
    uploadedTime: number;
    ownerName?: string;
    fileDecryptionHeader?: string;
    fileNonce?: string;
    fileKey?: string;
    lockerType?: string;
    lockerInfoData?: LockerInfoData;
}
