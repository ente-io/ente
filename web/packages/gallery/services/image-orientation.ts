import log from "ente-base/log";
import {
    extractRawExif,
    parseExif,
    parseExifOrientation,
    type ExifOrientation,
    type RawExifTags,
} from "ente-gallery/services/exif";
import type { ParsedMetadata } from "ente-media/file-metadata";

export interface OrientedImageURLResult {
    imageURL: string;
    exif?: { tags: RawExifTags; parsed: ParsedMetadata };
    orientedImageURL?: string;
}

// For the orientations 5 and above, the height and width of the images are
// to be swapped for properly rendering them.
export const dimensionsForExifOrientation = (
    width: number,
    height: number,
    orientation: ExifOrientation,
) => (orientation >= 5 ? { width: height, height: width } : { width, height });

// Applies the correct canvas affine transform (mirror/rotate/flip) for each of
// the 8 orientation cases.
//
// Note: the width and height passed here must be the pre-rotation (un-swapped)
// dimensions. For orientations >= 5 this function does not swap them; it instead
// rotates the canvas coordinate system via ctx.transform(), and that rotation is
// what produces the visually swapped result.
export const applyExifOrientationTransform = (
    ctx: CanvasRenderingContext2D,
    orientation: ExifOrientation,
    width: number,
    height: number,
) => {
    switch (orientation) {
        case 1:
            // Horizontal (normal)
            break;
        case 2:
            // Mirror horizontal
            ctx.transform(-1, 0, 0, 1, width, 0);
            break;
        case 3:
            // Rotate 180
            ctx.transform(-1, 0, 0, -1, width, height);
            break;
        case 4:
            // Mirror vertical
            ctx.transform(1, 0, 0, -1, 0, height);
            break;
        case 5:
            // Mirror horizontal and rotate 270 CW
            ctx.transform(0, 1, 1, 0, 0, 0);
            break;
        case 6:
            // Rotate 90 CW
            ctx.transform(0, 1, -1, 0, height, 0);
            break;
        case 7:
            // Mirror horizontal and rotate 90 CW
            ctx.transform(0, -1, -1, 0, height, width);
            break;
        case 8:
            // Rotate 270 CW
            ctx.transform(0, -1, 1, 0, 0, width);
            break;
    }
};

// Wrapper function which applies the transformation and then
// draws the image.
export const drawImageWithExifOrientation = (
    ctx: CanvasRenderingContext2D,
    image: CanvasImageSource,
    orientation: ExifOrientation,
    width: number,
    height: number,
) => {
    applyExifOrientationTransform(ctx, orientation, width, height);
    ctx.drawImage(image, 0, 0, width, height);
};

/**
 * Return the original display URL and, when needed, an orientation-corrected
 * object URL for the image.
 *
 * @param imageURL The renderable object URL of the image associated with the file.
 * @param originalImageBlob The original image associated with the file, as a Blob.
 *
 * This is currently shared by the file viewer and the image editor. Callers
 * should use `orientedImageURL ?? imageURL` for display, and only revoke
 * `orientedImageURL` because it is created here.
 */
export const orientedImageURL = async (
    imageURL: string,
    originalImageBlob: Blob,
): Promise<OrientedImageURLResult> => {
    let exif: OrientedImageURLResult["exif"] | undefined;
    let orientation: ExifOrientation | undefined;

    // Extract and parse the embedded metadata once, then read the orientation
    // tag from the raw Exif/XMP tags.
    try {
        const tags = await extractRawExif(originalImageBlob);
        const parsed = parseExif(tags);
        exif = { tags, parsed };
        orientation = parseExifOrientation(tags);
    } catch (e) {
        log.warn("Failed to extract exif for image orientation", e);
        return { imageURL };
    }

    // Missing orientation and orientation 1 are both no-op cases, so keep the
    // original display URL and return any metadata we were able to parse.
    if (!orientation || orientation == 1) return { imageURL, exif };

    const correctedImageURL = await canvasOrientedImageURL(
        imageURL,
        orientation,
    );
    return { imageURL, exif, orientedImageURL: correctedImageURL };
};

/**
 * Draw the image into a new canvas with the requested Exif orientation applied,
 * returning a new object URL for that canvas output.
 *
 * @param imageURL The renderable object URL of the image associated with the file.
 * @param orientation The Exif orientation extracted from the image metadata.
 */
const canvasOrientedImageURL = async (
    imageURL: string,
    orientation: ExifOrientation,
) => {
    const image = await loadImage(imageURL);
    const width = image.naturalWidth;
    const height = image.naturalHeight;
    const canvasDimensions = dimensionsForExifOrientation(
        width,
        height,
        orientation,
    );

    const canvas = document.createElement("canvas");
    canvas.width = canvasDimensions.width;
    canvas.height = canvasDimensions.height;

    const ctx = canvas.getContext("2d");
    if (!ctx) throw new Error("Failed to get canvas 2D context");

    drawImageWithExifOrientation(ctx, image, orientation, width, height);

    return URL.createObjectURL(await canvasBlob(canvas));
};

const loadImage = (imageURL: string) =>
    new Promise<HTMLImageElement>((resolve, reject) => {
        const image = new Image();
        image.onload = () => resolve(image);
        image.onerror = reject;
        image.src = imageURL;
    });

const canvasBlob = (canvas: HTMLCanvasElement) =>
    new Promise<Blob>((resolve, reject) =>
        canvas.toBlob((blob) =>
            blob ? resolve(blob) : reject(new Error("toBlob failed")),
        ),
    );
