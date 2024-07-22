import piexif from "piexifjs";

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
export const setJPEGExifDateTimeOriginal = async (
    jpegBlob: Blob,
    date: Date,
) => {
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
