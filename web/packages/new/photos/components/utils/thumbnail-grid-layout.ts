export const thumbnailGap = 4;
export const thumbnailMaxHeight = 180;
export const thumbnailMaxWidth = 180;
export const thumbnailLayoutMinColumns = 4;

export interface ThumbnailGridLayoutParams {
    /**
     * The overall width available to us.
     *
     * This is the height that is the input to the computation, stashed here so
     * that other parts of the code downstream can also get at it if needed.
     */
    containerWidth: number;
    /**
     * `true` if the container width is classified as a smaller screen for the
     * purpose of the thumbnail grid, and some dimensions are reduced to account
     * for the lesser space available to us.
     */
    isSmallerLayout: boolean;
    /**
     * The inline padding (px) of the thumbnail grid.
     */
    paddingInline: number;
    /**
     * The number of columns in the thumbnail grid.
     */
    columns: number;
    /**
     * The width (px) of each item.
     */
    itemWidth: number;
    /**
     *  The height (px) of each item.
     */
    itemHeight: number;
    /**
     * The gap (px) between each grid item.
     */
    gap: number;
}

/**
 * Determine the layout parameters for a grid of thumbnails that would best fit
 * the given width under various constraints.
 *
 * @param containerWidth The width available to the container. In our case,
 * since the thumbnail grids span the entire available width, this is the width
 * of the page itself.
 */
export const computeThumbnailGridLayoutParams = (
    containerWidth: number,
): ThumbnailGridLayoutParams => {
    const isSmallerLayout = !(
        containerWidth >
        thumbnailLayoutMinColumns * thumbnailMaxWidth
    );
    const paddingInline = getGapFromScreenEdge(containerWidth);
    const fittableColumns = getFractionFittableColumns(containerWidth);

    let columns = Math.floor(fittableColumns);
    if (columns < thumbnailLayoutMinColumns) {
        columns = thumbnailLayoutMinColumns;
    }

    const shrinkRatio = getShrinkRatio(containerWidth, columns);
    const itemHeight = thumbnailMaxHeight * shrinkRatio;
    const itemWidth = thumbnailMaxWidth * shrinkRatio;
    const gap = thumbnailGap;

    return {
        containerWidth,
        isSmallerLayout,
        paddingInline,
        columns,
        itemWidth,
        itemHeight,
        gap,
    };
};

const getFractionFittableColumns = (width: number): number =>
    (width - 2 * getGapFromScreenEdge(width) + thumbnailGap) /
    (thumbnailMaxWidth + thumbnailGap);

const getGapFromScreenEdge = (width: number) =>
    width > thumbnailLayoutMinColumns * thumbnailMaxWidth ? 24 : 4;

const getShrinkRatio = (width: number, columns: number) =>
    (width - 2 * getGapFromScreenEdge(width) - (columns - 1) * thumbnailGap) /
    (columns * thumbnailMaxWidth);
