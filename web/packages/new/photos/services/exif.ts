import log from "@/base/log";
import ExifReader from "exifreader";
import type { EnteFile } from "../types/file";

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
 * The de facto reference for Exif (in its general form) is exiftool.
 * https://exiftool.org/TagNames
 *
 * The library we use is https://github.com/mattiasw/ExifReader.
 */

// eslint-disable-next-line @typescript-eslint/no-empty-function
export const extractExif = () => {};

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
 * These dates are all in the local time of the place where the photo was taken.
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
const parseExifDates = ({ exif }: ExifReader.ExpandedTags) => ({
    DateTimeOriginal: parseExifDate(
        exif?.DateTimeOriginal,
        exif?.OffsetTimeOriginal,
    ),
    DateTimeDigitized: parseExifDate(
        exif?.DateTimeDigitized,
        exif?.OffsetTimeDigitized,
    ),
    DateTime: parseExifDate(exif?.DateTime, exif?.OffsetTime),
});

const parseExifDate = (
    dateTag: ExifReader.StringArrayTag | undefined,
    offsetTag: ExifReader.StringArrayTag | undefined,
) => {
    const [dateString] = dateTag?.value ?? [];
    if (!dateString) return undefined;

    const components = dateString
        .trim()
        .replace(" ", ":")
        .split(":")
        .map((s) => parseInt(s, 10));
    const [YYYY, MM, DD, HH, mm, ss] = components;
    if (
        !(
            YYYY !== undefined &&
            YYYY >= 0 &&
            YYYY <= 9999 &&
            MM !== undefined &&
            MM >= 1 &&
            MM <= 12 &&
            DD !== undefined &&
            DD >= 1 &&
            DD <= 31 &&
            HH !== undefined &&
            HH >= 0 &&
            HH <= 23 &&
            mm !== undefined &&
            mm >= 0 &&
            mm <= 59 &&
            ss !== undefined &&
            ss >= 0 &&
            ss <= 59
        )
    ) {
        log.warn(`Ignoring malformed Exif date ${dateString}`);
        return undefined;
    }

    const date = new Date(YYYY, MM - 1, DD, HH, mm, ss);



    const [offsetString] = offsetTag?.value ?? [];
    return "";
};

/**
 * Index Exif in the given {@link EnteFile}.
 *
 * This function is invoked as part of the ML indexing pipeline, which is why it
 * uses the same "index" nomenclature. But what it does is more of an extraction
 * / backfill process. The idea is that since we are anyways retrieving the
 * original file to index it for faces and CLIP, we might as well extract the
 * Exif and store it as part of the derived data (so that future features can
 * more readily use it), and also backfill any fields that old clients might've
 * not extracted during their file uploads.
 *
 * @param enteFile The {@link EnteFile} which we're indexing. This is the file
 * whose metadata we update if needed (for backfilling).
 *
 * @param blob A {@link Blob} containing the {@link enteFile}'s data. This is
 * where we extract the Exif from.
 *
 */
export const indexExif = async (enteFile: EnteFile, blob: Blob) => {
    // [Note: Defining "raw" Exif]
    //
    // Our goal is to get a "raw" JSON representing all the Exif data associated
    // with a file. This goal is tricky to achieve for the following reasons:
    //
    // -   While Exif itself is a standard, with a standard set of tags (a
    //     numeric id), in practice vendors can use tags more than what are
    //     currently listed in the standard.
    //
    // -   We're not just interested in Exif tags, but rather at all forms of
    //     metadata (e.g. XMP, IPTC) that can be embedded in a file.
    //
    // By default, the library we use (ExifReader) returns a merged object
    // containing all tags it understands from all forms of metadata that it
    // knows about.
    //
    // This implicit whitelist behaviour can be turned off by specifying the
    // `includeUnknown` flag, but this behaviour acts as a safeguard against us
    // trying to include unbounded amounts of data. e.g. there is an Exif tag
    // for thumbnails, which contains a raw image. We don't want this data to
    // blow up the size of the Exif we extract, so we filter it out. However, if
    // we tell the library to include unknown tags, we might get files with
    // other forms of embedded images.
    //
    // So we keep the default behaviour of returning only the tags that the
    // library knows about. Luckily for us, it returns all the XMP tags even if
    // this flag is specified, and that is one place where we'd like unknown
    // tags so that we can selectively start adding support for them.
    //
    // The other default behaviour, of returning a merged object, is a bit more
    // problematic for our use case, since it loses information. To keep things
    // more deterministic, we use the `expanded` flag which returns all these
    // different forms of metadata separately.
    //
    // Generally for each tag (but not for always), we get an entry with an
    // "id", "value" (e.g. the raw bytes), and a "description" (which is the raw
    // data parsed to a form that is more usable). Technically speaking, the
    // value is the raw data we want, but in some cases, the availability of a
    // pre-parsed description will be convenient too. So we don't prune
    // anything, and keep all three.
    //
    // All this means we end up with a JSON whose exact structure is tied to the
    // library we're using (ExifReader), and even its version (the library
    // reserves the right to change the formatting of the "description" fields
    // in minor version updates).
    //
    // So this is not really "raw" Exif. But with that caveat out of the way,
    // practically this should be raw enough given the tradeoffs mentioned
    // above, and consuming this JSON should be easy enough for arbitrary
    // clients without needing to know about ExifReader specifically.
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

    backfill(enteFile, tags);

    return tags;
};

// eslint-disable-next-line @typescript-eslint/no-unused-vars
const backfill = (_enteFile: EnteFile, _tags: ExifReader.ExpandedTags) => {
    // const date =
};
