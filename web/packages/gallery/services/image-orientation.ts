import type { ExifOrientation } from "ente-gallery/services/exif";

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
