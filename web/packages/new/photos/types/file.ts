import type { Metadata } from "@/media/types/file";
import {
    VISIBILITY_STATE,
    type EncryptedMagicMetadata,
    type MagicMetadataCore,
} from "./magicMetadata";

export interface MetadataFileAttributes {
    encryptedData: string;
    decryptionHeader: string;
}
export interface S3FileAttributes {
    objectKey: string;
    decryptionHeader: string;
}

export interface FileInfo {
    fileSize: number;
    thumbSize: number;
}

export interface EncryptedEnteFile {
    id: number;
    collectionID: number;
    ownerID: number;
    file: S3FileAttributes;
    thumbnail: S3FileAttributes;
    metadata: MetadataFileAttributes;
    info: FileInfo;
    magicMetadata: EncryptedMagicMetadata;
    pubMagicMetadata: EncryptedMagicMetadata;
    encryptedKey: string;
    keyDecryptionNonce: string;
    isDeleted: boolean;
    updationTime: number;
}

export interface EnteFile
    extends Omit<
        EncryptedEnteFile,
        | "metadata"
        | "pubMagicMetadata"
        | "magicMetadata"
        | "encryptedKey"
        | "keyDecryptionNonce"
    > {
    metadata: Metadata;
    magicMetadata: FileMagicMetadata;
    pubMagicMetadata: FilePublicMagicMetadata;
    isTrashed?: boolean;
    key: string;
    src?: string;
    srcURLs?: SourceURLs;
    msrc?: string;
    html?: string;
    w?: number;
    h?: number;
    title?: string;
    deleteBy?: number;
    isSourceLoaded?: boolean;
    conversionFailed?: boolean;
    isConverted?: boolean;
}

export interface LivePhotoSourceURL {
    image: () => Promise<string>;
    video: () => Promise<string>;
}

export interface LoadedLivePhotoSourceURL {
    image: string;
    video: string;
}

export interface SourceURLs {
    url: string | LivePhotoSourceURL | LoadedLivePhotoSourceURL;
    isOriginal: boolean;
    isRenderable: boolean;
    type: "normal" | "livePhoto";
    /**
     * Best effort attempt at obtaining the MIME type.
     *
     * Known cases where it is missing:
     *
     * - Live photos (these have a different code path for obtaining the URL).
     * - A video that is passes the isPlayable test in the browser.
     *
     */
    mimeType?: string;
}

export interface TrashRequest {
    items: TrashRequestItems[];
}

export interface TrashRequestItems {
    fileID: number;
    collectionID: number;
}

export interface FileWithUpdatedMagicMetadata {
    file: EnteFile;
    updatedMagicMetadata: FileMagicMetadata;
}

export interface FileWithUpdatedPublicMagicMetadata {
    file: EnteFile;
    updatedPublicMagicMetadata: FilePublicMagicMetadata;
}

export interface FileMagicMetadataProps {
    visibility?: VISIBILITY_STATE;
    filePaths?: string[];
}

export type FileMagicMetadata = MagicMetadataCore<FileMagicMetadataProps>;

export interface FilePublicMagicMetadataProps {
    editedTime?: number;
    editedName?: string;
    caption?: string;
    uploaderName?: string;
    w?: number;
    h?: number;
}

export type FilePublicMagicMetadata =
    MagicMetadataCore<FilePublicMagicMetadataProps>;
