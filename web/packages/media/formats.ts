/**
 * Image file extensions that we know the browser is unlikely to have native
 * support for.
 */
const nonWebImageFileExtensions = [
    "heic",
    "rw2",
    "tiff",
    "arw",
    "cr3",
    "cr2",
    "raf",
    "nef",
    "psd",
    "dng",
    "tif",
];

/**
 * Return `true` if {@link extension} is from amongst a known set of image file
 * extensions that we know that the browser is unlikely to have native support
 * for. If we want to display such files in the browser, we'll need to convert
 * them to some other format first.
 */
export const isNonWebImageFileExtension = (extension: string) =>
    nonWebImageFileExtensions.includes(extension.toLowerCase());

/**
 * Return `true` if {@link extension} in for an HEIC-like file.
 */
export const isHEICExtension = (extension: string) => {
    const ext = extension.toLowerCase();
    return ext == "heic" || ext == "heif";
};
