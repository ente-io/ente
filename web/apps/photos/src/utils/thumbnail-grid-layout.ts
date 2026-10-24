import {
    thumbnailGap,
    thumbnailGridPadding,
    type ThumbnailGridLayoutParams,
} from "ente-new/photos/components/utils/thumbnail-grid-layout";

const thumbnailSize = 200;
const minimumColumns = 4;

/** Photos uses fixed-size thumbnails, shrinking only on narrow layouts. */
export const computePhotosThumbnailGridLayoutParams = (
    containerWidth: number,
): ThumbnailGridLayoutParams => {
    const availableWidth = Math.max(
        0,
        containerWidth - 2 * thumbnailGridPadding,
    );
    const columns = Math.max(
        minimumColumns,
        Math.floor(
            (availableWidth + thumbnailGap) / (thumbnailSize + thumbnailGap),
        ),
    );
    const itemSize = Math.min(
        thumbnailSize,
        Math.max(0, (availableWidth - (columns - 1) * thumbnailGap) / columns),
    );

    return {
        containerWidth,
        isSmallerLayout: itemSize < thumbnailSize,
        paddingInline: thumbnailGridPadding,
        columns,
        itemWidth: itemSize,
        itemHeight: itemSize,
        gap: thumbnailGap,
    };
};
