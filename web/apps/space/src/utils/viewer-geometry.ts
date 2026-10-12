export interface ViewerRect {
    x: number;
    y: number;
    w: number;
    h: number;
}

// image is where the whole photo is, visible is the part of it that shows.
export interface ViewerPhotoState {
    image: ViewerRect;
    visible: ViewerRect;
    radius: number;
}

export const tilePhotoState = (
    tile: ViewerRect,
    photo: { width: number; height: number },
    radius: number,
): ViewerPhotoState => {
    const scale = Math.max(tile.w / photo.width, tile.h / photo.height);
    const w = photo.width * scale;
    const h = photo.height * scale;
    return {
        image: {
            x: tile.x + (tile.w - w) / 2,
            y: tile.y + (tile.h - h) / 2,
            w,
            h,
        },
        visible: { ...tile },
        radius,
    };
};

export const fullPhotoState = (
    rect: ViewerRect,
    radius = 0,
): ViewerPhotoState => ({ image: { ...rect }, visible: { ...rect }, radius });

// A photo zoomed in past the viewport is cut to it.
export const shownPhotoState = (
    image: ViewerRect,
    viewport: ViewerRect,
    radius: number,
): ViewerPhotoState => {
    if (image.w <= viewport.w && image.h <= viewport.h)
        return fullPhotoState(image, radius);
    const x = Math.max(image.x, viewport.x);
    const y = Math.max(image.y, viewport.y);
    const w = Math.min(image.x + image.w, viewport.x + viewport.w) - x;
    const h = Math.min(image.y + image.h, viewport.y + viewport.h) - y;
    return {
        image: { ...image },
        visible: { x, y, w: Math.max(0, w), h: Math.max(0, h) },
        radius,
    };
};

const mix = (a: number, b: number, t: number) => a + (b - a) * t;

const mixRect = (a: ViewerRect, b: ViewerRect, t: number): ViewerRect => ({
    x: mix(a.x, b.x, t),
    y: mix(a.y, b.y, t),
    w: mix(a.w, b.w, t),
    h: mix(a.h, b.h, t),
});

export const mixPhotoState = (
    from: ViewerPhotoState,
    to: ViewerPhotoState,
    t: number,
): ViewerPhotoState => ({
    image: mixRect(from.image, to.image, t),
    visible: mixRect(from.visible, to.visible, t),
    radius: Math.max(0, mix(from.radius, to.radius, t)),
});

export const photoStateTravel = (a: ViewerPhotoState, b: ViewerPhotoState) =>
    Math.max(
        Math.abs(a.visible.x - b.visible.x),
        Math.abs(a.visible.y - b.visible.y),
        Math.abs(a.visible.x + a.visible.w - b.visible.x - b.visible.w),
        Math.abs(a.visible.y + a.visible.h - b.visible.y - b.visible.h),
    );

export const viewerBackgroundOpacity = (t: number) => {
    const k = Math.min(1, Math.max(0, t));
    return 1 - (1 - k) ** 2;
};
