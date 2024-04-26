import type { ElectronFile } from "@/next/types/file";

export interface Location {
    latitude: number;
    longitude: number;
}

export interface FileWithCollection {
    localID: number;
    collectionID: number;
    isLivePhoto?: boolean;
    fileOrPath?: File | string;
    livePhotoAssets?: LivePhotoAssets;
}

export interface LivePhotoAssets {
    image: File | string;
    video: File | string;
}

export interface ParsedExtractedMetadata {
    location: Location;
    creationTime: number;
    width: number;
    height: number;
}

export interface PublicUploadProps {
    token: string;
    passwordToken: string;
    accessedThroughSharedURL: boolean;
}
