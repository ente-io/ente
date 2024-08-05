import { encryptMetadata } from "@/base/crypto/ente";
import { authenticatedRequestHeaders, ensureOk } from "@/base/http";
import { apiURL } from "@/base/origins";
import { type EnteFile } from "@/new/photos/types/file";
import { FileType } from "./file-type";

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
 * Mutable private metadata associated with an {@link EnteFile}.
 *
 * -   Unlike {@link Metadata}, this can change after the file has been
 *     uploaded.
 *
 * -   Unlike {@link PublicMagicMetadata}, this is only available to the owner
 *     of the file.
 *
 * For historical reasons, the unqualified phrase "magic metadata" in various
 * APIs refers to the (this) private metadata, even though the mutable public
 * metadata is the much more frequently used of the two. See: [Note: Metadatum].
 */
export interface PrivateMagicMetadata {
    /**
     * The visibility of the file.
     *
     * The file's visibility is user specific attribute, and thus we keep it in
     * the private magic metadata. This allows the file's owner to share a file
     * and independently edit its visibility without revealing their visibility
     * preference to the other people with whom they have shared the file.
     */
    visibility?: ItemVisibility;
}

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

/**
 * Mutable public metadata associated with an {@link EnteFile}.
 *
 * -   Unlike {@link Metadata}, this can change after the file has been
 *     uploaded.
 *
 * -   Unlike {@link PrivateMagicMetadata}, this is available to all the people
 *     with whom the file has been shared.
 *
 * For more details, see [Note: Metadatum].
 */
export interface PublicMagicMetadata {
    /**
     * Modified value of the date time associated with an {@link EnteFile}.
     *
     * Epoch microseconds.
     *
     * This field stores edits to the {@link creationTime} {@link Metadata}
     * field.
     */
    editedTime?: number;
    /**
     * Modified name of the {@link EnteFile}.
     *
     * This field stores edits to the {@link title} {@link Metadata} field.
     */
    editedName?: string;
    /**
     * An arbitrary caption / description string that the user has added to the
     * file.
     *
     * The length of this field is capped to some arbitrary maximum by client
     * side checks.
     */
    caption?: string;
    uploaderName?: string;
    w?: number;
    h?: number;
}

/**
 * Magic metadata, either public and private, as persisted and used by remote.
 *
 * This is the encrypted magic metadata as persisted on remote, and this is what
 * clients get back when they sync with remote. Alongwith the encrypted blob and
 * decryption header, it also contains a few properties useful for clients to
 * track changes and ensure that they have the latest metadata synced locally.
 *
 * Both public and private magic metadata fields use the same structure.
 */
interface RemoteMagicMetadata {
    /**
     * Monotonically increasing iteration of this metadata object.
     *
     * The version starts at 1. Each time a client updates the underlying magic
     * metadata JSONs for a file, it increments this version number.
     */
    version: number;
    /**
     * The number of keys with non-null (and non-undefined) values in the
     * encrypted JSON object that the encrypted metadata blob contains.
     *
     * During edits and updates, this number should be greater than or equal to
     * the previous version.
     *
     * > Clients are expected to retain the magic metadata verbatim so that they
     * > don't accidentally overwrite fields that they might not understand.
     */
    count: number;
    /**
     * The encrypted data.
     *
     * This is a base64 string representing the bytes obtained by encrypting the
     * string representation of the underlying magic metadata JSON object.
     */
    data: string;
    /**
     * The base64 encoded decryption header that will be needed for the client
     * for decrypting {@link data}.
     */
    header: string;
}

/**
 * The shape of the JSON body payload expected by the APIs that update the
 * public and private magic metadata fields associated with a file.
 */
interface UpdateMagicMetadataRequest {
    /** The list of (file id, new magic metadata) pairs to update */
    metadataList: {
        /** File ID */
        id: number;
        /** The new metadata to use */
        magicMetadata: RemoteMagicMetadata;
    }[];
}

/**
 * A function that can be used to encrypt the contents of a metadata field
 * associated with a file.
 *
 * This is parameterized to allow us to use either the regular
 * {@link encryptMetadata} or the web worker wrapper for it.
 */
export type EncryptMetadataF = typeof encryptMetadata;

/**
 * Construct an remote update request payload from the public or private magic
 * metadata JSON object for an {@link enteFile}, using the provided
 * {@link encryptMetadataF} function to encrypt the JSON.
 */
export const updateMagicMetadataRequest = async (
    enteFile: EnteFile,
    metadata: PrivateMagicMetadata | PublicMagicMetadata,
    metadataVersion: number,
    encryptMetadataF: EncryptMetadataF,
): Promise<UpdateMagicMetadataRequest> => {
    // Drop all null or undefined values to obtain the syncable entries.
    const validEntries = Object.entries(metadata).filter(
        ([, v]) => v !== null && v !== undefined,
    );

    const { encryptedDataB64, decryptionHeaderB64 } = await encryptMetadataF(
        Object.fromEntries(validEntries),
        enteFile.key,
    );

    return {
        metadataList: [
            {
                id: enteFile.id,
                magicMetadata: {
                    version: metadataVersion,
                    count: validEntries.length,
                    data: encryptedDataB64,
                    header: decryptionHeaderB64,
                },
            },
        ],
    };
};

/**
 * Update the magic metadata for a list of files.
 *
 * @param request The list of file ids and the updated encrypted magic metadata
 * associated with each of them.
 */
export const putFilesMagicMetadata = async (
    request: UpdateMagicMetadataRequest,
) =>
    ensureOk(
        await fetch(await apiURL("/files/magic-metadata"), {
            method: "PUT",
            headers: await authenticatedRequestHeaders(),
            body: JSON.stringify(request),
        }),
    );

/**
 * Update the public magic metadata for a list of files.
 *
 * @param request The list of file ids and the updated encrypted magic metadata
 * associated with each of them.
 */
export const putFilesPublicMagicMetadata = async (
    request: UpdateMagicMetadataRequest,
) =>
    ensureOk(
        await fetch(await apiURL("/files/public-magic-metadata"), {
            method: "PUT",
            headers: await authenticatedRequestHeaders(),
            body: JSON.stringify(request),
        }),
    );

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
     * The date/time when this photo was taken.
     *
     * Logically this is a date in local timezone of the place where the photo
     * was taken. See: [Note: Photos are always in local date/time].
     */
    creationDate?: ParsedMetadataDate;
    /** The GPS coordinates where the photo was taken. */
    location?: { latitude: number; longitude: number };
}

/**
 * [Note: Photos are always in local date/time]
 *
 * Photos out in the wild frequently do not have associated timezone offsets for
 * the date/time embedded in their metadata. This is a artifact of an era where
 * cameras didn't know often even know their date/time correctly, let alone the
 * UTC offset of their local data/time.
 *
 * This is beginning to change with smartphone cameras, and is even reflected in
 * the standards. e.g. Exif metadata now has auxillary "OffsetTime*" tags for
 * indicating the UTC offset of the local date/time in the existing Exif tags
 * (See: [Note: Exif dates]).
 *
 * So a photos app needs to deal with a mixture of photos whose dates may or may
 * not have UTC offsets. This is fact #1.
 *
 * Users expect to see the time they took the photo, not the time in the place
 * they are currently. People expect a New Year's Eve photo from a vacation to
 * show up as midnight, not as (e.g.) 19:30 IST. This is fact #2.
 *
 * Combine these two facts, and if you ponder a bit, you'll find that there is
 * only one way for a photos app to show / sort / label the date – by using the
 * local date/time without the attached UTC offset, **even if it is present**.
 *
 * The UTC offset is still useful though, and we don't want to lose that
 * information. The number of photos with a UTC offset will only increase. And
 * whenever it is present, it provides additional context for the user.
 *
 * So we keep both the local date/time string (an ISO 8601 string guaranteed to
 * be without an associated UTC offset), and an (optional) UTC offset string.
 *
 * It is important to NOT think of the local date/time string as an instant of
 * time that can be converted to a UTC timestamp. It cannot be converted to a
 * UTC timestamp because while it itself might have the optional associated UTC
 * offset, its siblings photos might not. The only way to retain their
 * comparability is to treat them all the "time zone where the photo was taken".
 *
 * Finally, while this is all great, we still have existing code that deals with
 * UTC timestamps. So we also retain the existing `creationTime` UTC timestamp,
 * but this should be considered deprecated, and over time we should move
 * towards using the `dateTime` string.
 */
export interface ParsedMetadataDate {
    /**
     * A local date/time.
     *
     * This is a partial ISO 8601 date/time string guaranteed not to have a
     * timezone offset. e.g. "2023-08-23T18:03:00.000".
     */
    dateTime: string;
    /**
     * An optional offset from UTC.
     *
     * This is an optional UTC offset string of the form "±HH:mm" or "Z",
     * specifying the timezone offset for {@link dateTime} when available.
     */
    offsetTime: string | undefined;
    /**
     * UTC epoch microseconds derived from {@link dateTime} and
     * {@link offsetTime}.
     *
     * When the {@link offsetTime} is present, this will accurately reflect a
     * UTC timestamp. When the {@link offsetTime} is not present it convert to a
     * UTC timestamp by assuming that the given {@link dateTime} is in the local
     * time where this code is running. This is a good assumption but not always
     * correct (e.g. vacation photos).
     */
    timestamp: number;
}

/**
 * Parse a partial or full ISO 8601 string into a {@link ParsedMetadataDate}.
 *
 * @param s A partial or full ISO 8601 string. That is, it is a string of the
 * form "2023-08-23T18:03:00.000+05:30" or "2023-08-23T12:33:00.000Z" with all
 * components except the year potentially missing.
 *
 * @return A {@link ParsedMetadataDate}, or `undefined` if {@link s} cannot be
 * parsed.
 *
 * ---
 * Some examples:
 *
 * -   "2023"                          => ("2023-01-01T00:00:00.000", undefined)
 * -   "2023-08"                       => ("2023-08-01T00:00:00.000", undefined)
 * -   "2023-08-23"                    => ("2023-08-23T00:00:00.000", undefined)
 * -   "2023-08-23T18:03:00"           => ("2023-08-23T18:03:00.000", undefined)
 * -   "2023-08-23T18:03:00+05:30"     => ("2023-08-23T18:03:00.000', "+05:30")
 * -   "2023-08-23T18:03:00.000+05:30" => ("2023-08-23T18:03:00.000", "+05:30")
 * -   "2023-08-23T12:33:00.000Z"      => ("2023-08-23T12:33:00.000", "Z")
 */
export const parseMetadataDate = (
    s: string,
): ParsedMetadataDate | undefined => {
    // Construct the timestamp using the original string itself. If s is
    // parseable as a date, then this'll be give us the correct UTC timestamp.
    // If the UTC offset is not present, then this will be in the local
    // (current) time.
    const timestamp = new Date(s).getTime() * 1000;
    if (isNaN(timestamp)) {
        // s in not a well formed ISO 8601 date time string.
        return undefined;
    }

    // Now we try to massage s into two parts - the local date/time string, and
    // an UTC offset string.

    let offsetTime: string | undefined;
    let sWithoutOffset: string;

    // Check to see if there is a time-zone descriptor of the form "Z" or
    // "±05:30" or "±0530" at the end of s.
    const m = s.match(/Z|[+-]\d\d:?\d\d$/);
    if (m?.index) {
        sWithoutOffset = s.substring(0, m.index);
        offsetTime = s.substring(m.index);
    } else {
        sWithoutOffset = s;
    }

    // Convert sWithoutOffset - a potentially partial ISO 8601 string - to a
    // canonical ISO 8601 string.
    //
    // In its full generality, this is non-trivial. The approach we take is:
    //
    // 1.   Rely on the browser to be able to partial ISO 8601 string. This
    //      relies on non-standard behaviour but works in practice seemingly.
    //
    // 2.   Get an ISO 8601 representation of it. This is standard.
    //
    // A thing to watch out for is that browsers treat date only and date time
    // strings differently when the offset is not present (as would be for us).
    //
    // > When the time zone offset is absent, date-only forms are interpreted as
    // > a UTC time and date-time forms are interpreted as local time.
    // >
    // > https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Date#date_time_string_format
    //
    // For our purpose, we want to always interpret them as UTC time. This way,
    // when we later gets back its string representation for step 2, we will get
    // back the same numerical value, and can just chop off the "Z".
    //
    // So if the length of the string is less than or equal to yyyy-mm-dd (10),
    // then we use it verbatim, otherwise we append a "Z".

    const date = new Date(
        sWithoutOffset + (sWithoutOffset.length <= 10 ? "" : "Z"),
    );

    // The string returned by `toISOString` is guaranteed to be UTC and denoted
    // by the suffix "Z". If we chop that off, we get back a canonical
    // representation we wish for: A otherwise well-formed ISO 9601 string but
    // any time zone descriptor.
    const dateTime = dropLast(date.toISOString());

    return { dateTime, offsetTime, timestamp };
};

const dropLast = (s: string) => (s ? s.substring(0, s.length - 1) : s);
