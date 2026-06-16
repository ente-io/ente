import type { ExifOrientation } from "ente-gallery/services/exif";

export const dimensionsForExifOrientation = (
    width: number,
    height: number,
    orientation: ExifOrientation,
) => (orientation >= 5 ? { width: height, height: width } : { width, height });

export const applyExifOrientationTransform = (
    ctx: CanvasRenderingContext2D,
    orientation: ExifOrientation,
    width: number,
    height: number,
) => {
    switch (orientation) {
        case 1:
            break;
        case 2:
            ctx.transform(-1, 0, 0, 1, width, 0);
            break;
        case 3:
            ctx.transform(-1, 0, 0, -1, width, height);
            break;
        case 4:
            ctx.transform(1, 0, 0, -1, 0, height);
            break;
        case 5:
            ctx.transform(0, 1, 1, 0, 0, 0);
            break;
        case 6:
            ctx.transform(0, 1, -1, 0, height, 0);
            break;
        case 7:
            ctx.transform(0, -1, -1, 0, height, width);
            break;
        case 8:
            ctx.transform(0, -1, 1, 0, 0, width);
            break;
    }
};

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
