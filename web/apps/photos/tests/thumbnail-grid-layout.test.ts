import { computeThumbnailGridLayoutParams } from "ente-new/photos/components/utils/thumbnail-grid-layout";
import { describe, expect, test } from "vitest";
import { computePhotosThumbnailGridLayoutParams } from "../src/utils/thumbnail-grid-layout";

describe("Photos thumbnail layout", () => {
    test("keeps 200px squares and 4px gaps instead of stretching to fill", () => {
        const layout = computePhotosThumbnailGridLayoutParams(1333);
        expect(layout).toMatchObject({
            columns: 6,
            itemWidth: 200,
            itemHeight: 200,
            gap: 4,
            paddingInline: 24,
            isSmallerLayout: false,
        });
    });

    test("adds a column only when another full thumbnail and gap fit", () => {
        expect(computePhotosThumbnailGridLayoutParams(1063).columns).toBe(4);
        expect(computePhotosThumbnailGridLayoutParams(1064).columns).toBe(5);
    });

    test.each([320, 375, 720, 859, 860, 1063, 1064, 1440, 1920])(
        "fits square thumbnails within a %ipx container",
        (width) => {
            const layout = computePhotosThumbnailGridLayoutParams(width);
            const usedWidth =
                2 * layout.paddingInline +
                layout.columns * layout.itemWidth +
                (layout.columns - 1) * layout.gap;
            expect(usedWidth).toBeLessThanOrEqual(width);
            expect(layout.itemWidth).toBe(layout.itemHeight);
            expect(layout.itemWidth).toBeLessThanOrEqual(200);
        },
    );

    test("preserves four shrinking columns on narrow layouts", () => {
        expect(computePhotosThumbnailGridLayoutParams(375)).toMatchObject({
            columns: 4,
            itemWidth: 78.75,
            itemHeight: 78.75,
            isSmallerLayout: true,
        });
    });

    test("leaves the shared public-album layout unchanged", () => {
        expect(computeThumbnailGridLayoutParams(1333).columns).toBe(7);
    });
});
