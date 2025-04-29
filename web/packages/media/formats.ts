/**
 * List used by {@link needsJPEGConversion}.
 */
const needsJPEGConversionExtensions = [
    "arw",
    "cr2",
    "cr3",
    "dng",
    "heic",
    "jp2",
    "nef",
    "psd",
    "rw2",
    "tif",
    "tiff",
];

/**
 * Return `true` if {@link extension} is from amongst a known set of image file
 * extensions that (a) we know that the browser is unlikely to support, and (b)
 * which we should be able to convert to JPEG when running in our desktop app.
 *
 * These two are independent constraints, but we only return true if we satisfy
 * both of them instead of having two disjoint lists.
 */
export const needsJPEGConversion = (extension: string) =>
    needsJPEGConversionExtensions.includes(extension.toLowerCase());

/**
 * Return `true` if {@link extension} in for an HEIC-like file.
 */
export const isHEICExtension = (extension: string) => {
    const ext = extension.toLowerCase();
    return ext == "heic" || ext == "heif";
};
