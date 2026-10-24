export const thumbnailGap = 4;
export const thumbnailGridPadding = 24;
const thumbnailMaxWidth = 180;
const thumbnailLayoutMinColumns = 4;

export interface ThumbnailGridLayoutParams {
    containerWidth: number;
    isSmallerLayout: boolean;
    paddingInline: number;
    columns: number;
    itemWidth: number;
    itemHeight: number;
    gap: number;
}

export const computeThumbnailGridLayoutParams = (
    containerWidth: number,
    { fixedThumbnailSize }: { fixedThumbnailSize?: number } = {},
): ThumbnailGridLayoutParams => {
    const paddingInline = thumbnailGridPadding;
    const targetSize = fixedThumbnailSize ?? thumbnailMaxWidth;
    const availableWidth = containerWidth - 2 * paddingInline;
    const fittableColumns =
        (availableWidth + thumbnailGap) / (targetSize + thumbnailGap);

    let columns = Math.floor(fittableColumns);
    if (columns < thumbnailLayoutMinColumns) {
        columns = thumbnailLayoutMinColumns;
    }

    const fittedSize =
        (availableWidth - (columns - 1) * thumbnailGap) / columns;
    // Fixed-size grids leave unused space at the end instead of stretching.
    const itemSize =
        fixedThumbnailSize === undefined
            ? fittedSize
            : Math.min(fixedThumbnailSize, Math.max(0, fittedSize));
    const isSmallerLayout =
        fixedThumbnailSize === undefined
            ? !(containerWidth > thumbnailLayoutMinColumns * thumbnailMaxWidth)
            : itemSize < fixedThumbnailSize;
    const gap = thumbnailGap;

    return {
        containerWidth,
        isSmallerLayout,
        paddingInline,
        columns,
        itemWidth: itemSize,
        itemHeight: itemSize,
        gap,
    };
};
