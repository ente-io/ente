import { lowercaseExtension } from "@/base/file";
import log from "@/base/log";
import { FILE_TYPE } from "@/media/file-type";
import piexif from "piexifjs";
import type { EnteFile } from "../types/file";

/**
 * Return a new stream after applying Exif updates if applicable to the given
 * stream, otherwise return the original.
 *
 * This function is meant to provide a stream that can be used to download (or
 * export) a file to the user's computer after applying any Exif updates to the
 * original file's data.
 *
 * -   This only updates JPEG files.
 *
 * -   For JPEG files, the DateTimeOriginal Exif entry is updated to reflect the
 *     time that the user edited within Ente.
 *
 * @param enteFile The {@link EnteFile} whose data we want.
 *
 * @param stream A {@link ReadableStream} containing the original data for
 * {@link enteFile}.
 *
 * @returns A new {@link ReadableStream} with updates if any updates were
 * needed, otherwise return the original stream.
 */
export const updateExifIfNeededAndPossible = async (
    enteFile: EnteFile,
    stream: ReadableStream<Uint8Array>,
): Promise<ReadableStream<Uint8Array>> => {
    // Not an image.
    if (enteFile.metadata.fileType != FILE_TYPE.IMAGE) return stream;
    // Time was not edited.
    if (!enteFile.pubMagicMetadata?.data.editedTime) return stream;

    const fileName = enteFile.metadata.title;
    const extension = lowercaseExtension(fileName);
    // Not a JPEG (likely).
    if (extension != "jpeg" && extension != "jpg") return stream;

    const blob = await new Response(stream).blob();
    try {
        const updatedBlob = await setJPEGExifDateTimeOriginal(
            blob,
            new Date(enteFile.pubMagicMetadata.data.editedTime / 1000),
        );
        return updatedBlob.stream();
    } catch (e) {
        log.error(`Failed to modify Exif date for ${fileName}`, e);
        // We used the file's extension to determine if this was a JPEG, but
        // this is not a guarantee. Misnamed files, while rare, do exist. So in
        // that is the error thrown by the underlying library, fallback to the
        // original instead of causing the entire download or export to fail.
        if (
            e instanceof Error &&
            e.message.endsWith("Given file is neither JPEG nor TIFF.")
        ) {
            return blob.stream();
        }
        throw e;
    }
};

/**
 * Return a new blob with the "DateTimeOriginal" Exif tag set to the given
 * {@link date}.
 *
 * @param jpegBlob A {@link Blob} containing JPEG data.
 *
 * @param date A {@link Date} to use as the value for the Exif
 * "DateTimeOriginal" tag.
 *
 * @returns A new blob derived from {@link jpegBlob} but with the updated date.
 */
const setJPEGExifDateTimeOriginal = async (jpegBlob: Blob, date: Date) => {
    let dataURL = await blobToDataURL(jpegBlob);
    // Since we pass a Blob without an associated type, we get back a generic
    // data URL of the form "data:application/octet-stream;base64,...".
    //
    // Modify it to have a `image/jpeg` MIME type.
    dataURL = "data:image/jpeg;base64" + dataURL.slice(dataURL.indexOf(","));

    const exifObj = piexif.load(dataURL);
    if (!exifObj.Exif) exifObj.Exif = {};
    exifObj.Exif[piexif.ExifIFD.DateTimeOriginal] =
        convertToExifDateFormat(date);
    const exifBytes = piexif.dump(exifObj);
    const exifInsertedFile = piexif.insert(exifBytes, dataURL);

    return dataURLToBlob(exifInsertedFile);
};

/**
 * Convert a blob to a `data:` URL.
 */
const blobToDataURL = (blob: Blob) =>
    new Promise<string>((resolve) => {
        const reader = new FileReader();
        // We need to cast to a string here. This should be safe since MDN says:
        //
        // > the result attribute contains the data as a data: URL representing
        // > the file's data as a base64 encoded string.
        // >
        // > https://developer.mozilla.org/en-US/docs/Web/API/FileReader/readAsDataURL
        reader.onload = () => resolve(reader.result as string);
        reader.readAsDataURL(blob);
    });

/**
 * Convert a `data:` URL to a blob.
 *
 * Requires `connect-src data:` in the CSP (since it internally uses `fetch` to
 * perform the conversion).
 */
const dataURLToBlob = (dataURI: string) =>
    fetch(dataURI).then((res) => res.blob());

/**
 * Convert the given {@link Date} to a format that is expected by Exif for the
 * DateTimeOriginal tag.
 */
const convertToExifDateFormat = (date: Date) =>
    `${date.getFullYear()}:${date.getMonth() + 1}:${date.getDate()} ${date.getHours()}:${date.getMinutes()}:${date.getSeconds()}`;
