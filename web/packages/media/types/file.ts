import type { ParsedMetadataDate } from "../file";
import type { FileType } from "../file-type";

/**
 * Information about the file that never changes post upload.
 *
 * [Note: Metadatum]
 *
 * There are three different sources of metadata relating to a file.
 *
 * 1. Metadata
 * 2. Magic metadata
 * 3. Public magic metadata
 *
 * The names of API entities are such for historical reasons, but we can think
 * of them as:
 *
 * 1. Metadata
 * 2. Private mutable metadata
 * 3. Shared mutable metadata
 *
 * Metadata is the original metadata that we attached to the file when it was
 * uploaded. It is immutable, and it never changes.
 *
 * Later on, the user might make changes to the file's metadata. Since the
 * metadata is immutable, we need a place to keep these mutations.
 *
 * Some mutations are "private" to the user who owns the file. For example, the
 * user might archive the file. Such modifications get written to (2), Private
 * Mutable Metadata.
 *
 * Other mutations are "public" across all the users with whom the file is
 * shared. For example, if the user (owner) edits the name of the file, all
 * people with whom this file is shared can see the new edited name. Such
 * modifications get written to (3), Shared Mutable Metadata.
 *
 * When the client needs to show a file, it needs to "merge" in 2 or 3 of these
 * sources.
 *
 * -   When showing a shared file, (1) and (3) are merged, with changes from (3)
 *     taking precedence, to obtain the full metadata pertinent to the file.
 *
 * -   When showing a normal (un-shared) file, (1), (2) and (3) are merged, with
 *     changes from (2) and (3) taking precedence, to obtain the full metadata.
 *     (2) and (3) have no intersection of keys, so they can be merged in any
 *     order.
 *
 * While these sources can be conceptually merged, it is important for the
 * client to also retain the original sources unchanged. This is because the
 * metadatas (any of the three) might have keys that the current client does not
 * yet understand, so when updating some key, say filename in (3), it should
 * only edit the key it knows about but retain the rest of the source JSON
 * unchanged.
 */
export interface Metadata {
    /** The "Ente" file type - image, video or live photo. */
    fileType: FileType;
    /**
     * The file name.
     *
     * See: [Note: File name for local EnteFile objects]
     */
    title: string;
    /**
     * The time when this file was created (epoch microseconds).
     *
     * For photos (and images in general), this is our best attempt (using Exif
     * and other metadata, or deducing it from file name for screenshots without
     * any embedded metadata) at detecting the time when the photo was taken.
     *
     * If nothing can be found, then it is set to the current time at the time
     * of the upload.
     */
    creationTime: number;
    modificationTime: number;
    latitude: number;
    longitude: number;
    hasStaticThumbnail?: boolean;
    hash?: string;
    imageHash?: string;
    videoHash?: string;
    localID?: number;
    version?: number;
    deviceFolder?: string;
}

/**
 * Metadata about a file extracted from various sources (like Exif) when
 * uploading it into Ente.
 *
 * Depending on the file type and the upload sequence, this data can come from
 * various places:
 *
 * -   For images it comes from the Exif and other forms of metadata (XMP, IPTC)
 *     embedded in the file.
 *
 * -   For videos, similarly it is extracted from the metadata embedded in the
 *     file using ffmpeg.
 *
 * -   From various sidecar files (like metadata JSONs) that might be sitting
 *     next to the original during an import.
 *
 * These bits then get distributed and saved in the various metadata fields
 * associated with an {@link EnteFile} (See: [Note: Metadatum]).
 *
 * The advantage of having them be attached to an {@link EnteFile} is that it
 * allows us to perform operations using these attributes without needing to
 * re-download the original image.
 *
 * The disadvantage is that it increases the network payload (anything attached
 * to an {@link EnteFile} comes back in the diff response), and thus latency and
 * local storage costs for all clients. Thus, we need to curate what gets
 * preseved within the {@link EnteFile}'s metadatum.
 */
export interface ParsedMetadata {
    /** The width of the image, in pixels. */
    width?: number;
    /** The height of the image, in pixels. */
    height?: number;
    /**
     * The date (and time) when this photo was taken.
     *
     * This in the local timezone of the place where the photo was taken, but it
     * also has additional fields we need.
     *
     * See: [Note: Photos are always in local date/time]
     */
    creationMetadataDate?: ParsedMetadataDate /** TODO: Exif */;
    /** The time when this photo was taken. */
    creationTime?: number;
    /** The GPS coordinates where the photo was taken. */
    location?: { latitude: number; longitude: number };
}
