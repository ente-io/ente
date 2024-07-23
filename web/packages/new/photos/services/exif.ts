import ExifReader from "exifreader";
import type { EnteFile } from "../types/file";

/**
 * Index Exif in the given file.
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
 * [Note: Exif not EXIF]
 *
 * The standard uses "Exif" (not "EXIF") to refer to itself. We do the same.
 */
export const indexExif = async (_enteFile: EnteFile, blob: Blob) => {
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
    // above, and consuming this JSON should be reasonable enough for arbitrary
    // clients without needing to know about ExifReader specifically.
    const tags = await ExifReader.load(await blob.arrayBuffer(), {
        async: true,
        expanded: true,
    });

    return tags;
};
