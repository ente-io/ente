import type { Metadata } from "./types/file";

export const hasFileHash = (file: Metadata) =>
    !!file.hash || (!!file.imageHash && !!file.videoHash);

/**
 * [Note: Photos are always in local date/time]
 *
 * Photos out in the wild frequently do not have associated timezone offsets for
 * the datetime embedded in their metadata. This is a artifact of an era where
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
 * only one way for a photos app to show / sort / label (as a day) – by using
 * the local datetime without the attached UTC offset **even if it is present**.
 *
 * The UTC offset is still useful though, and we don't want to lose that
 * information. The number of photos with a UTC offset will only increase. And
 * whenever it is present, it provides additional context for the user.
 *
 * So we keep both the local date/time string (an ISO8601 string guaranteed to
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
     * This is a partial ISO8601 datetime string guaranteed not to have a
     * timezone offset. e.g. "2023-08-23T18:03:00.000"
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
     * UTC timestamp. When the {@link offsetTime} is not present, this is not
     * necessarily accurate, since it then assumes that the given
     * {@link dateTime} is in the local time where this code is running. This is
     * a good assumption but not always correct (e.g. vacation photos).
     */
    timestamp: number;
}
