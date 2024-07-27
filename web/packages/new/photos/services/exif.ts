import { isDevBuild } from "@/base/env";
import log from "@/base/log";
import type { ParsedMetadata } from "@/media/types/file";
import ExifReader from "exifreader";
import type { ParsedExtractedMetadata } from "../types/metadata";
import { isInternalUser } from "./feature-flags";

// TODO: Exif: WIP flag to inspect the migration from old to new lib.
export const wipNewLib = async () => isDevBuild && (await isInternalUser());

export const cmpNewLib = (
    oldLib: ParsedExtractedMetadata,
    newLib: ParsedMetadata,
) => {
    if (
        oldLib.creationTime == newLib.creationTime &&
        oldLib.location.latitude == newLib.location?.latitude &&
        oldLib.location.longitude == newLib.location?.longitude
    ) {
        if (oldLib.width == newLib.width && oldLib.height == newLib.height)
            log.info("Exif migration ✅");
        else log.info("Exif migration 🟢");
        log.debug(() => ["exif/cmp", { oldLib, newLib }]);
    } else {
        log.info("Exif migration - Potential mismatch ❗️🚩");
        log.info({ oldLib, newLib });
    }
};

/**
 * Extract Exif and other metadata from the given file.
 *
 * [Note: Exif]
 *
 * Exif is a standard for metadata embedded in photos. Exif tags arise from the
 * TIFF specification but now can be found in other file formats, notably JPG,
 * PNG, AVI, MOV, TIFF-based RAW images (and TIFF itself)
 *
 * The standard uses "Exif" (not "EXIF") to refer to itself. We do the same.
 *
 * Exif is now commonly used as a synedoche for all forms of metadata that gets
 * embedded in a file, and this is also how we use the term. So these functions
 * extract and operate on not just Exif tags, but also XMP (XML metadata
 * embedded in images) and IPTC (another metadat standard) tags.
 *
 * A list for metadata tags can be found in exiftool's documentation:
 * https://exiftool.org/TagNames
 *
 * The library we use is https://github.com/mattiasw/ExifReader.
 */
export const extractExif = async (file: File) =>
    await extractRawExif(file).then(parseExif);

/**
 * Parse an already extracted {@link RawExifTags}.
 *
 * See: {@link extractExif}. This function does just the parsing step, for use
 * when we've already extracted the raw data.
 */
export const parseExif = (tags: RawExifTags) => {
    const location = parseLocation(tags);
    const creationDate = parseCreationDate(tags);
    const dimensions = parseDimensions(tags);

    const metadata: ParsedMetadata = dimensions ?? {};
    if (creationDate) metadata.creationTime = creationDate.getTime() * 1000;
    if (location) metadata.location = location;
    return metadata;
};

/**
 * Parse GPS location from the metadata embedded in the file.
 */
const parseLocation = (tags: RawExifTags) => {
    const latitude = tags.gps?.Latitude;
    const longitude = tags.gps?.Longitude;
    return latitude !== undefined && longitude !== undefined
        ? { latitude, longitude }
        : undefined;
};

/**
 * Parse a single "best" creation date for an image from the metadata embedded
 * in the file.
 *
 * A file has multiple types of metadata, and each of these has multiple types
 * of dates, so we use some an a heuristic ordering (based on experience with
 * the photos we find out in the wild) to pick a "best" date.
 */
const parseCreationDate = (tags: RawExifTags) => {
    const { DateTimeOriginal, DateTimeDigitized, MetadataDate, DateTime } =
        parseDates(tags);
    return DateTimeOriginal ?? DateTimeDigitized ?? MetadataDate ?? DateTime;
};

/**
 * Dates extracted from the Exif and other metadata embedded in a file.
 *
 * These are the dates corresponding to the various options we show to the user
 * for the "Fix date" functionality. These don't come solely from the Exif but
 * from all forms of metadata we support (Exif, XMP, IPTC). They roughly
 * correspond to the three Exif DateTime* tags, and the XMP MetadataDate tag.
 */
interface ParsedExifDates {
    DateTimeOriginal: Date | undefined;
    DateTimeDigitized: Date | undefined;
    DateTime: Date | undefined;
    MetadataDate: Date | undefined;
}

/**
 * Extract dates from Exif and other metadata for the given file.
 */
export const extractExifDates = (file: File): Promise<ParsedExifDates> =>
    extractRawExif(file).then(parseDates);

/**
 * Parse all date related fields from the metadata embedded in the file,
 * grouping them into chunks that somewhat reflect the Exif ontology.
 */
const parseDates = (tags: RawExifTags) => {
    // Ignore 0 and NaN
    //
    // Some customers (not sure how prevalent this is) reported photos with Exif
    // dates set to "0000:00:00 00:00:00". So we ignore any date whose epoch is
    // 0, and try with a subsequent (possibly correct) date in the sequence.
    //
    // If the string we used to construct the date is invalid, then `getTime`
    // will return `NaN`. Ignore these too.
    const valid = (d: Date | undefined) => (d?.getTime() ? d : undefined);

    const exif = parseExifDates(tags);
    const iptc = parseIPTCDates(tags);
    const xmp = parseXMPDates(tags);

    log.debug(() => ["exif/dates", { exif, iptc, xmp }]);

    return {
        DateTimeOriginal:
            valid(xmp.DateTimeOriginal) ??
            valid(iptc.DateTimeOriginal) ??
            valid(exif.DateTimeOriginal) ??
            valid(xmp.DateCreated),
        DateTimeDigitized:
            valid(xmp.DateTimeDigitized) ??
            valid(iptc.DateTimeDigitized) ??
            valid(exif.DateTimeDigitized) ??
            valid(xmp.CreateDate),
        DateTime: valid(xmp.DateTime ?? exif.DateTime ?? xmp.ModifyDate),
        MetadataDate: valid(xmp.MetadataDate),
    };
};

/**
 * Parse a date from an Exif date and offset tag combination.
 *
 * @param tags Metadata tags associated with a file.
 *
 * @param dateTag The name of the date tag to use.
 *
 * @param offsetTag The name of the offset tag corresponding to {@link dateTag}.
 *
 * @returns a {@link Date} (UTC epoch milliseconds).
 *
 * [Note: Exif dates]
 *
 * The most important bit we usually wish out of Exif is the date and time when
 * the photo was taken. The Exif specification has the following tags related to
 * photo's date:
 *
 * -   DateTimeOriginal
 * -   DateTimeDigitized (aka "CreateDate")
 * -   DateTime (aka "ModifyDate")
 *
 * DateTimeOriginal is meant to signify best when the original image was taken,
 * and we use it as the photo's creation date whenever it is present. If not, we
 * fallback to DateTimeDigitized or DateTime (in that order).
 *
 * Each of these is a string of the format
 *
 *     YYYY:MM:DD HH:mm:ss
 *
 * where
 *
 *     YYYY  4 digit (zero padded) year
 *     MM    2 digit (zero padded) month, with Jan as 01 and Dec as 12.
 *     DD    2 digit (zero padded) day of the month (1 to 31)
 *     HH    2 digit (zero padded) hours since midnight (00 to 23)
 *     mm    2 digit (zero padded) minutes (00 to 59)
 *     ss    2 digit (zero padded) seconds (00 to 59)
 *
 * Additionally (and optionally), there are three SubSecTime* tags that provide
 * the fractional seconds (one for each of the above):
 *
 * -   SubSecTimeOriginal
 * -   SubSecTimeDigitized
 * -   SubSecTime
 *
 * Each of which is a string specifying the fractional digits.
 *
 * The dates are all in the local time of the place where the photo was taken.
 * To convert these to UTC, we also need to know the offset from UTC of that
 * local time. This is provided by the three OffsetTime* tags (one for each of
 * the above):
 *
 * -   OffsetTimeOriginal
 * -   OffsetTimeDigitized
 * -   OffsetTime
 *
 * Each of these is a string of the format
 *
 *     ±HH:mm
 *
 * denoting the signed hour and minute offset from UTC.
 *
 * Note that these OffsetTime* tags are relatively new additions (prior to
 * smartphones, cameras did not have a good way of knowing their TZ), and most
 * old photos will not have this information. In such cases, we assume that
 * these photos are in the local time where this code is running. This is
 * manifestly going to be incorrect in some cases, but it is a better assumption
 * than assuming UTC, which, while deterministic, is going to incorrect in an
 * overwhelming majority of cases.
 */
const parseExifDates = ({ exif }: RawExifTags) => ({
    DateTimeOriginal: parseExifDate(
        exif?.DateTimeOriginal,
        exif?.SubSecTimeOriginal,
        exif?.OffsetTimeOriginal,
    ),
    DateTimeDigitized: parseExifDate(
        exif?.DateTimeDigitized,
        exif?.SubSecTimeDigitized,
        exif?.OffsetTimeDigitized,
    ),
    DateTime: parseExifDate(exif?.DateTime, exif?.SubSecTime, exif?.OffsetTime),
});

const parseExifDate = (
    dateTag: ExifReader.StringArrayTag | undefined,
    subSecTag: ExifReader.StringArrayTag | undefined,
    offsetTag: ExifReader.StringArrayTag | undefined,
) => {
    const [dateString] = dateTag?.value ?? [];
    if (!dateString) return undefined;

    const [subSecString] = subSecTag?.value ?? [];
    const [offsetString] = offsetTag?.value ?? [];

    // Perform minor syntactic changes to the Exif date, and add the optional
    // offset, to construct a string in the Javascript date time string format.
    // https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Date#date_time_string_format
    //
    //     YYYY:MM:DD HH:mm:ss±HH:mm
    //     YYYY-MM-DDTHH:mm:ss±HH:mm
    //
    // When the offset string is missing, the date time is interpreted as local
    // time. This is the behaviour we want.
    //
    // For details see [Note: Exif dates]

    return new Date(
        dateString.replace(":", "-").replace(":", "-").replace(" ", "T") +
            (subSecString ? "." + subSecString : "") +
            (offsetString ?? ""),
    );
};

/**
 * Parse date related tags from XMP.
 *
 * The XMP information in the file can have the date related information in tags
 * spread across multiple namespaces.
 *
 * For a list of XMP tags, see https://exiftool.org/TagNames/XMP.html.
 */
const parseXMPDates = ({ xmp }: RawExifTags) => ({
    /* XMP namespace is indicated for each group */
    // exif:
    DateTimeOriginal: parseXMPDate(xmp?.DateTimeOriginal),
    DateTimeDigitized: parseXMPDate(xmp?.DateTimeDigitized),
    // exif: or tiff:
    DateTime: parseXMPDate(xmp?.DateTime),
    // xmp:
    CreateDate: parseXMPDate(xmp?.CreateDate),
    ModifyDate: parseXMPDate(xmp?.ModifyDate),
    MetadataDate: parseXMPDate(xmp?.MetadataDate),
    // photoshop:
    DateCreated: parseXMPDate(xmp?.DateCreated),
});

/**
 * Parse an XMP date tag.
 *
 * [Note: XMP dates]
 *
 * XMP dates use a format same as the ISO-8601 format that is used by JavaScript
 * as its date time string format.
 *
 *     YYYY-MM-DDThh:mm:ss.sTZD
 *
 * The main difference being, unlike JavaScript, all of the above components
 * except YYYY are optional. In practice, browsers gracefully handle these
 * scenarios, so we can directly use the JavaScript date constructor.
 *
 * References:
 * - https://www.iptc.org/std/photometadata/specification/IPTC-PhotoMetadata#date-value-type
 * - https://developer.adobe.com/xmp/docs/XMPNamespaces/XMPDataTypes/#date
 */
const parseXMPDate = (xmpTag: ExifReader.XmpTag | undefined) => {
    if (!xmpTag) return undefined;
    const s = xmpTag.value;
    if (typeof s != "string") return undefined;

    return new Date(s);
};

/**
 * Parse date related tags from IPTC.
 */
const parseIPTCDates = ({ iptc }: RawExifTags) => ({
    DateTimeOriginal: parseIPTCDate(
        iptc?.["Date Created"],
        iptc?.["Time Created"],
    ),
    DateTimeDigitized: parseIPTCDate(
        iptc?.["Digital Creation Date"],
        iptc?.["Digital Creation Time"],
    ),
});

/**
 * Parse an IPTC date tag.
 *
 * [Note: IPTC dates]
 *
 * IPTC date time values are split across two tag:
 *
 * - A tag containing the date as as 8 digit number of the form `YYYYMMDD`.
 *
 * - A tag containing the time as an 11 character string of the form
 *   `HHMMSS±HHMM`.
 *
 * They lack separators, but together these tags are meant to encode the same
 * information as the ISO 8601 date format (that XMP and JavaScript also use).
 *
 * Reference:
 * - http://www.iptc.org/std/IIM/4.1/specification/IIMV4.1.pdf
 *
 * ---
 *
 * @param dateTag The tag containing the date part of the date.
 *
 * @param timeTag The tag containing the time part of the date.
 */
const parseIPTCDate = (
    dateTag: ExifReader.NumberArrayTag | undefined,
    timeTag: ExifReader.NumberArrayTag | undefined,
) => {
    // The library we use (ExifReader) parses them into a usable representation,
    // which we can use directly. Some notes:
    //
    // -   There are currently no separate TypeScript types for the IPTC tags,
    //     and instead they are listed as part of the ExifTags.
    //
    // -   For the date, whenever possible ExifReader parses the raw data into a
    //     description of the form 'YYYY-MM-DD' (See `getCreationDate` in its
    //     source code).
    //
    // -   For the time, whenever possible ExifReader parses the raw data into a
    //     description either of the form 'HH:mm:ss` or `HH:mm:ss±HH:mm` (See
    //     `getCreationTime` in its source code).
    if (!dateTag) return undefined;
    let s = dateTag.description;

    if (timeTag) s = s + "T" + timeTag.description;

    return new Date(s);
};

/**
 * Parse the width and height of the image from the metadata embedded in the
 * file.
 */
const parseDimensions = (tags: RawExifTags) => {
    // Go through all possiblities in order, returning the first pair with both
    // the width and height defined, and non-zero.
    const pair = (w: number | undefined, h: number | undefined) =>
        w && h ? { width: w, height: h } : undefined;

    return (
        pair(
            tags.exif?.ImageWidth?.value,
            /* The Exif spec calls it ImageLength, not ImageHeight. */
            tags.exif?.ImageLength?.value,
        ) ??
        pair(
            tags.exif?.PixelXDimension?.value,
            tags.exif?.PixelYDimension?.value,
        ) ??
        pair(
            parseXMPNum(tags.xmp?.ImageWidth),
            parseXMPNum(tags.xmp?.ImageLength),
        ) ??
        pair(
            parseXMPNum(tags.xmp?.PixelXDimension),
            parseXMPNum(tags.xmp?.PixelYDimension),
        ) ??
        pair(
            tags.pngFile?.["Image Width"]?.value,
            tags.pngFile?.["Image Height"]?.value,
        ) ??
        pair(
            tags.gif?.["Image Width"]?.value,
            tags.gif?.["Image Height"]?.value,
        ) ??
        pair(tags.riff?.ImageWidth?.value, tags.riff?.ImageHeight?.value) ??
        pair(
            tags.file?.["Image Width"]?.value,
            tags.file?.["Image Height"]?.value,
        )
    );
};

/**
 * Try to parse the given XMP tag as a number.
 */
const parseXMPNum = (xmpTag: ExifReader.XmpTag | undefined) => {
    if (!xmpTag) return undefined;
    const s = xmpTag.value;
    if (typeof s != "string") return undefined;

    const n = parseInt(s, 10);
    if (isNaN(n)) return undefined;
    return n;
};

export type RawExifTags = Omit<ExifReader.ExpandedTags, "Thumbnail" | "xmp"> & {
    xmp?: ExifReader.XmpTags;
};

/**
 * Extract "raw" exif and other metadata from the given file.
 *
 * @param blob A {@link Blob} containing the data of an {@link EnteFile}.
 *
 * @return A JSON object containing the raw exif and other metadata that was
 * found in the given {@link blob}.
 *
 * ---
 *
 * [Note: Defining "raw" Exif]
 *
 * We wish for a canonical "raw" JSON representing all the Exif data associated
 * with a file. This goal is tricky to achieve because:
 *
 * -   While Exif itself is a standard, with a standard set of tags (a numeric
 *     id), in practice vendors can use tags more than what are currently listed
 *     in the standard.
 *
 * -   We're not just interested in Exif tags, but rather at all forms of
 *     metadata (e.g. XMP, IPTC) that can be embedded in a file.
 *
 * By default, the library we use (ExifReader) returns a merged object
 * containing all tags it understands from all forms of metadata that it knows
 * about.
 *
 * Since it only returns the tags it understands, it acts an an implicit
 * whitelist. This implicit whitelist behaviour can be turned off by specifying
 * the `includeUnknown` flag, but for our case it is useful since it acts as a
 * safeguard against extracting an unbounded amounts of data (for example, there
 * is an Exif tag for thumbnails. While we specifically filter out that
 * particular tag, it is not hard to imagine some other unforseen vendor
 * specific tag containing a similarly large amounts of embedded data).
 *
 * So we keep the default behaviour of returning only the tags that the library
 * knows about. Luckily for us, it returns all the XMP tags even if this flag is
 * specified, and that is one place where we'd like unknown tags so that we can
 * selectively start adding support for them.
 *
 * The other default behaviour, of returning a merged object, is a bit more
 * problematic for our use case, since it loses information. Thus, to keep
 * things more deterministic, we specify the `expanded` flag which returns all
 * these different forms of metadata separately.
 *
 * That's for the tags we get. Now to their contents. Generally for each tag
 * (but not for always), we get an entry with an "id", "value" (e.g. the raw
 * bytes), and a "description" (which is the raw data parsed to a form that is
 * more usable). Technically speaking, the value is the raw data we want, but in
 * some cases, the availability of a pre-parsed description will be convenient
 * too. So we don't prune anything, and keep all three.
 *
 * All this means we end up with a JSON whose exact structure is tied to the
 * library we're using (ExifReader), or even its version (the library reserves
 * the right to change the formatting of the "description" fields in minor
 * version updates).
 *
 * So this is not really "raw" Exif. But with that caveat out of the way,
 * practically this should be raw enough given the tradeoffs mentioned above,
 * while allowing us to consume this JSON in arbitrary clients without needing
 * to know about ExifReader specifically.
 */
export const extractRawExif = async (blob: Blob): Promise<RawExifTags> => {
    const tags = await ExifReader.load(await blob.arrayBuffer(), {
        async: true,
        expanded: true,
    });

    // Remove the embedded thumbnail (if any).
    delete tags.Thumbnail;
    delete tags.exif?.Thumbnail;

    // Remove the embedded MPF images (if any).
    //
    // The TypeScript definition is out of data and doesn't include the top
    // level 'mpf', so we need to cast. From the source:
    //
    // > The images can be accessed by the tags.Images array (tags.mpf.Images if
    // > using expanded: true).
    //
    delete (tags as Record<string, unknown>).mpf;

    // Remove the raw XMP (if any).
    //
    // The `includeUnknown` flag does not have any effect on the XMP parser, so
    // we already get all the key value pairs in the XMP as part of the "xmp"
    // object, retaining the raw string is unnecessary.
    //
    // We need to cast to remove the non-optional _raw property. Be aware that
    // this means that from this point onwards, the TypeScript type is out of
    // sync with the actual value (TypeScript type says _raw is always present,
    // while the actual value doesn't have it).
    delete (tags.xmp as Partial<typeof tags.xmp>)?._raw;

    return tags;
};
