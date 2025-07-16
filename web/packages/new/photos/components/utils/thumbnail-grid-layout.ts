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
        MIN_COLUMNS * IMAGE_CONTAINER_MAX_WIDTH
    );
    const paddingInline = getGapFromScreenEdge(containerWidth);
    const fittableColumns = getFractionFittableColumns(containerWidth);

    let columns = Math.floor(fittableColumns);
    if (columns < MIN_COLUMNS) {
        columns = MIN_COLUMNS;
    }

    const shrinkRatio = getShrinkRatio(containerWidth, columns);
    const itemHeight = IMAGE_CONTAINER_MAX_HEIGHT * shrinkRatio;
    const itemWidth = IMAGE_CONTAINER_MAX_WIDTH * shrinkRatio;
    const gap = GAP_BTW_TILES;

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

/* TODO: Some of this code is also duplicated elsewhere. See if those places can
   reuse the same function as above, with some extra params if needed.

   So that the duplication is easier to identify, keeping the duplication
   verbatim for now */

const GAP_BTW_TILES = 4;
const IMAGE_CONTAINER_MAX_HEIGHT = 180;
const IMAGE_CONTAINER_MAX_WIDTH = 180;
const MIN_COLUMNS = 4;

export const getFractionFittableColumns = (width: number): number =>
    (width - 2 * getGapFromScreenEdge(width) + GAP_BTW_TILES) /
    (IMAGE_CONTAINER_MAX_WIDTH + GAP_BTW_TILES);

export const getGapFromScreenEdge = (width: number) =>
    width > MIN_COLUMNS * IMAGE_CONTAINER_MAX_WIDTH ? 24 : 4;

export const getShrinkRatio = (width: number, columns: number) =>
    (width - 2 * getGapFromScreenEdge(width) - (columns - 1) * GAP_BTW_TILES) /
    (columns * IMAGE_CONTAINER_MAX_WIDTH);
