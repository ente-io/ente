/**
 * Compute optimal dimensions for a resized version of an image while
 * maintaining aspect ratio of the source image.
 *
 * @param width The width of the source image.
 *
 * @param height The height of the source image.
 *
 * @param maxDimension The maximum width of height of the resized image.
 *
 * This function returns a new size limiting it to maximum width and height
 * (both specified by {@link maxDimension}), while maintaining aspect ratio of
 * the source {@link width} and {@link height}.
 *
 * It returns `{0, 0}` for invalid inputs.
 */
export const scaledImageDimensions = (
    width: number,
    height: number,
    maxDimension: number,
): { width: number; height: number } => {
    if (width == 0 || height == 0) return { width: 0, height: 0 };
    const widthScaleFactor = maxDimension / width;
    const heightScaleFactor = maxDimension / height;
    const scaleFactor = Math.min(widthScaleFactor, heightScaleFactor);
    const resizedDimensions = {
        width: Math.round(width * scaleFactor),
        height: Math.round(height * scaleFactor),
    };
    if (resizedDimensions.width == 0 || resizedDimensions.height == 0)
        return { width: 0, height: 0 };
    return resizedDimensions;
};
