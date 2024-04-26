import type { ElectronFile } from "@/next/types/file";
import { Collection } from "types/collection";

export interface Location {
    latitude: number;
    longitude: number;
}

export interface UploadAsset {
    isLivePhoto?: boolean;
    file?: File | ElectronFile;
    fileOrPath?: File | ElectronFile;
    livePhotoAssets?: LivePhotoAssets;
}

export interface LivePhotoAssets {
    image: globalThis.File | ElectronFile;
    video: globalThis.File | ElectronFile;
}

export interface FileWithCollection extends UploadAsset {
    localID: number;
    collection?: Collection;
    collectionID?: number;
}

export interface LivePhotoAssets2 {
    image: File | string;
    video: File | string;
}

export interface FileWithCollection2 extends UploadAsset {
    localID: number;
    collection?: Collection;
    collectionID: number;
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
