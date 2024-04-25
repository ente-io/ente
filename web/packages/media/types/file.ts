import type { FILE_TYPE } from "../file-type";

/** Information about the file that never changes post upload. */
export interface Metadata {
    /**
     * The file name.
     *
     * See: [Note: File name for local EnteFile objects]
     */
    title: string;
    creationTime: number;
    modificationTime: number;
    latitude: number;
    longitude: number;
    /** The "Ente" file type. */
    fileType: FILE_TYPE;
    hasStaticThumbnail?: boolean;
    hash?: string;
    imageHash?: string;
    videoHash?: string;
    localID?: number;
    version?: number;
    deviceFolder?: string;
}
