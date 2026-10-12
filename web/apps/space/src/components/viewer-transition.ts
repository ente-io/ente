import {
    fullPhotoState,
    mixPhotoState,
    photoStateTravel,
    tilePhotoState,
    type ViewerPhotoState,
    type ViewerRect,
} from "utils/viewer-geometry";

const originAttribute = "data-space-viewer-origin";
const openDuration = 0.6;
const openBounce = 0.26;
const closeDuration = 0.46;
const swapFadeMs = 220;

export const viewerOriginKey = (spaceId?: string, postId?: number) =>
    spaceId && postId != undefined ? `${spaceId}:${postId}` : undefined;

export const findViewerOrigin = (key: string | undefined) =>
    key
        ? document.querySelector<HTMLElement>(
              `[${originAttribute}="${CSS.escape(key)}"]`,
          )
        : null;

interface ViewerFlightTarget {
    origin: HTMLElement;
    src: string;
    photo: { width: number; height: number };
}

const rectOf = (element: Element): ViewerRect => {
    const { left, top, width, height } = element.getBoundingClientRect();
    return { x: left, y: top, w: width, h: height };
};

const isOnScreen = (element: Element) => {
    const { x, y, w, h } = rectOf(element);
    return (
        w > 0 &&
        h > 0 &&
        x + w > 0 &&
        y + h > 0 &&
        x < window.innerWidth &&
        y < window.innerHeight
    );
};

const prefersReducedMotion = () =>
    window.matchMedia("(prefers-reduced-motion: reduce)").matches;

const tileRadius = (tile: Element) =>
    parseFloat(getComputedStyle(tile).borderTopLeftRadius) || 0;

const runSpring = ({
    from,
    to,
    velocity,
    duration,
    bounce,
    restDelta,
    onUpdate,
    onDone,
}: {
    from: number;
    to: number;
    velocity: number;
    duration: number;
    bounce: number;
    restDelta: number;
    onUpdate: (value: number) => void;
    onDone: () => void;
}) => {
    const stiffness = ((2 * Math.PI) / duration) ** 2;
    const damping = ((1 - bounce) * 4 * Math.PI) / duration;
    let value = from;
    let speed = velocity;
    let last = performance.now();
    let frame = requestAnimationFrame(function tick(now) {
        const dt = Math.min(0.064, Math.max(0, (now - last) / 1000));
        last = now;
        const steps = Math.max(1, Math.ceil(dt / 0.002));
        for (let i = 0; i < steps; i++) {
            speed +=
                (-stiffness * (value - to) - damping * speed) * (dt / steps);
            value += speed * (dt / steps);
        }
        if (
            Math.abs(value - to) < restDelta &&
            Math.abs(speed) < restDelta * 20
        ) {
            onUpdate(to);
            onDone();
            return;
        }
        onUpdate(value);
        frame = requestAnimationFrame(tick);
    });
    return () => cancelAnimationFrame(frame);
};

// A cropping window and the photo inside it, both moved with transforms.
const createFlyer = (root: HTMLElement, src: string, base: ViewerRect) => {
    const flyer = document.createElement("div");
    flyer.setAttribute("aria-hidden", "true");
    Object.assign(flyer.style, {
        height: `${base.h}px`,
        left: "0",
        overflow: "hidden",
        pointerEvents: "none",
        position: "absolute",
        top: "0",
        transformOrigin: "0 0",
        width: `${base.w}px`,
        willChange: "transform",
        zIndex: "1",
    });
    const image = document.createElement("img");
    image.alt = "";
    image.src = src;
    Object.assign(image.style, {
        display: "block",
        height: `${base.h}px`,
        left: "0",
        position: "absolute",
        top: "0",
        transformOrigin: "0 0",
        width: `${base.w}px`,
        willChange: "transform",
    });
    flyer.append(image);
    root.prepend(flyer);

    const draw = ({ image: i, visible: v, radius }: ViewerPhotoState) => {
        const sx = v.w / base.w;
        const sy = v.h / base.h;
        flyer.style.transform = `translate3d(${v.x}px, ${v.y}px, 0) scale(${sx}, ${sy})`;
        flyer.style.borderRadius = `${radius / sx}px / ${radius / sy}px`;
        image.style.transform = `translate3d(${(i.x - v.x) / sx}px, ${(i.y - v.y) / sy}px, 0) scale(${i.w / v.w}, ${i.h / v.h})`;
    };
    return { flyer, draw };
};

const createRider = (flyer: HTMLElement, tile: HTMLElement) => {
    const button = tile.parentElement?.querySelector<HTMLElement>(
        "[data-space-viewer-avatar]",
    );
    const avatar = button?.firstElementChild;
    if (!button || !(avatar instanceof HTMLElement)) return undefined;
    const tileRect = rectOf(tile);
    const avatarRect = rectOf(avatar);
    const left = avatarRect.x - tileRect.x;
    const fromBottom = tileRect.y + tileRect.h - avatarRect.y;
    const rider = avatar.cloneNode(true) as HTMLElement;
    for (const element of [rider, ...rider.querySelectorAll("*")])
        if (element instanceof HTMLElement) element.style.animation = "none";
    rider.setAttribute("aria-hidden", "true");
    Object.assign(rider.style, {
        left: "0",
        pointerEvents: "none",
        position: "absolute",
        top: "0",
        zIndex: "1",
    });
    flyer.after(rider);
    button.style.opacity = "0";

    return {
        draw: ({ visible: v }: ViewerPhotoState, t: number) => {
            rider.style.transform = `translate3d(${v.x + left}px, ${v.y + v.h - fromBottom}px, 0)`;
            rider.style.opacity = String(
                1 - Math.min(1, Math.max(0, t / 0.35)),
            );
        },
        remove: () => rider.remove(),
        reveal: () => {
            button.style.opacity = "";
        },
    };
};

// The tile stays empty until reveal, and the flying photo stays until release.
export const playViewerOpen = (
    root: HTMLElement,
    { origin, src, photo }: ViewerFlightTarget,
    to: ViewerRect,
    setProgress: (t: number) => void,
    onLanded: () => void,
) => {
    if (prefersReducedMotion() || !isOnScreen(origin)) return undefined;

    const from = tilePhotoState(rectOf(origin), photo, tileRadius(origin));
    let end = fullPhotoState(to);
    let t = 0;
    const { flyer, draw } = createFlyer(root, src, to);
    const rider = createRider(flyer, origin);
    const drawAt = (value: number) => {
        const state = mixPhotoState(from, end, value);
        draw(state);
        rider?.draw(state, value);
    };
    origin.style.opacity = "0";
    drawAt(0);
    setProgress(0);

    const release = () => {
        flyer.remove();
        rider?.remove();
    };
    const reveal = () => {
        origin.style.opacity = "";
        rider?.reveal();
    };
    const stopSpring = runSpring({
        from: 0,
        to: 1,
        velocity: 0,
        duration: openDuration,
        bounce: openBounce,
        restDelta: 1.5 / Math.max(1, photoStateTravel(from, end)),
        onUpdate: (value) => {
            t = value;
            drawAt(t);
            setProgress(t);
        },
        onDone: onLanded,
    });
    return {
        current: () => mixPhotoState(from, end, t),
        release,
        reveal,
        retarget: (rect: ViewerRect) => {
            end = fullPhotoState(rect);
            drawAt(t);
        },
        stop: () => {
            stopSpring();
            release();
            reveal();
        },
    };
};

// throwVelocity is in px per ms. A photo other than the tile's fades into it.
export const playViewerClose = (
    root: HTMLElement,
    { origin, src, photo }: ViewerFlightTarget,
    from: ViewerPhotoState,
    throwVelocity: { x: number; y: number },
    setProgress: (t: number) => void,
    onDone: () => void,
) => {
    if (prefersReducedMotion() || !isOnScreen(origin)) return undefined;

    const end = tilePhotoState(rectOf(origin), photo, tileRadius(origin));
    const { flyer, draw } = createFlyer(root, src, from.image);
    const rider = createRider(flyer, origin);
    const drawAt = (t: number) => {
        const state = mixPhotoState(end, from, t);
        draw(state);
        rider?.draw(state, t);
    };
    origin.style.opacity = "0";
    drawAt(1);

    const dx =
        end.visible.x +
        end.visible.w / 2 -
        (from.visible.x + from.visible.w / 2);
    const dy =
        end.visible.y +
        end.visible.h / 2 -
        (from.visible.y + from.visible.h / 2);
    const distance = Math.max(1, Math.hypot(dx, dy));
    const toward =
        ((throwVelocity.x * dx + throwVelocity.y * dy) / distance) * 1000;
    const tileImage = origin.querySelector<HTMLImageElement>(
        "img:not([aria-hidden])",
    );
    const isTilePhoto = tileImage?.currentSrc == src || tileImage?.src == src;

    const cleanUp = () => {
        origin.style.opacity = "";
        rider?.remove();
        rider?.reveal();
    };
    const stopSpring = runSpring({
        from: 1,
        to: 0,
        velocity: Math.min(1.2, Math.max(-8, -toward / distance)),
        duration: closeDuration,
        bounce: 0,
        restDelta: 0.5 / Math.max(1, photoStateTravel(from, end)),
        onUpdate: (t) => {
            drawAt(t);
            setProgress(t);
        },
        onDone: () => {
            cleanUp();
            if (isTilePhoto) {
                flyer.remove();
            } else {
                // The viewer unmounts next, so fade a copy.
                const ghost = flyer.cloneNode(true) as HTMLElement;
                Object.assign(ghost.style, {
                    position: "fixed",
                    zIndex: "1301",
                });
                document.body.append(ghost);
                flyer.remove();
                ghost
                    .animate([{ opacity: 1 }, { opacity: 0 }], {
                        duration: swapFadeMs,
                        easing: "ease",
                        fill: "forwards",
                    })
                    .addEventListener("finish", () => ghost.remove());
            }
            onDone();
        },
    });
    return () => {
        stopSpring();
        cleanUp();
        flyer.remove();
    };
};
