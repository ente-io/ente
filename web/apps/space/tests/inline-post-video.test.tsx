import type {
    DependencyList,
    EffectCallback,
    ReactElement,
    RefObject,
} from "react";
import { afterEach, beforeEach, expect, test, vi } from "vitest";
import { SpaceInlinePostVideo } from "../src/components/InlinePostVideo";
import type {
    SpacePostAsset,
    SpacePostAssetURLLoader,
} from "../src/services/space";

const mocks = vi.hoisted(() => ({
    refs: [] as { current: unknown }[],
    effects: [] as {
        dependencies: DependencyList;
        cleanup: ReturnType<EffectCallback>;
    }[],
    pendingEffects: [] as (() => void)[],
    refIndex: 0,
    effectIndex: 0,
    create: vi.fn(),
    register: vi.fn(),
    queue: vi.fn(),
}));

vi.mock("react", async (importOriginal) => ({
    ...(await importOriginal<typeof import("react")>()),
    useRef: (current: unknown) => {
        const index = mocks.refIndex++;
        return (mocks.refs[index] ??= { current });
    },
    useEffect: (effect: EffectCallback, dependencies: DependencyList) => {
        const index = mocks.effectIndex++;
        const previous = mocks.effects[index];
        if (
            !previous ||
            dependencies.some(
                (value, i) => !Object.is(value, previous.dependencies[i]),
            )
        )
            mocks.pendingEffects.push(() => {
                previous?.cleanup?.();
                mocks.effects[index] = { dependencies, cleanup: effect() };
            });
    },
}));
vi.mock("@mui/material", () => ({ Box: () => null }));
vi.mock("components/PostVideoContent", () => ({
    createSpaceVideoContent: mocks.create,
}));
vi.mock("components/feed-video-playback", () => ({
    registerFeedVideo: mocks.register,
}));
vi.mock("components/feed-video-preloading", () => ({
    queueFeedVideoLoad: mocks.queue,
}));
vi.mock("ente-base/log", () => ({ default: { warn: vi.fn() } }));

const asset = { objectKey: "video" } as SpacePostAsset;
const video = { asset, durationMs: 1000 };
const onLoadVideo = vi.fn<SpacePostAssetURLLoader>();
const container = { append: vi.fn() };
const button = { tabIndex: -1 };
const content = {
    element: { querySelector: () => button, remove: vi.fn() },
    video: Object.assign(new EventTarget(), {
        tabIndex: -1,
        muted: true,
        currentTime: 0,
        readyState: 0,
        HAVE_CURRENT_DATA: 2,
        poster: "",
        removeAttribute: vi.fn((name: string) => {
            if (name == "poster") content.video.poster = "";
        }),
    }),
    preload: vi.fn<() => Promise<void>>(),
    destroy: vi.fn(),
};
const registration = { setActive: vi.fn(), unregister: vi.fn() };
const request = {
    promise: Promise.resolve("blob:video"),
    setPreloading: vi.fn(),
    prioritize: vi.fn(),
    deprioritize: vi.fn(),
    cancel: vi.fn(),
};

beforeEach(() => {
    vi.clearAllMocks();
    mocks.refs = [];
    mocks.effects = [];
    mocks.pendingEffects = [];
    content.video.currentTime = 0;
    content.video.readyState = 0;
    content.video.poster = "";
    mocks.create.mockImplementation((_, load: SpacePostAssetURLLoader) => {
        content.preload.mockImplementation(() =>
            load(asset).then(() => undefined),
        );
        return content;
    });
    mocks.register.mockReturnValue(registration);
    mocks.queue.mockReturnValue(request);
});

const unmount = () => {
    mocks.effects.splice(0).forEach(({ cleanup }) => cleanup?.());
};

afterEach(unmount);

const render = (
    shouldPreload: boolean,
    isActive = false,
    imageUrl: string | undefined = "blob:cover",
) => {
    mocks.refIndex = 0;
    mocks.effectIndex = 0;
    const element = SpaceInlinePostVideo({
        video,
        onLoadVideo,
        shouldPreload,
        isActive,
        muted: true,
        imageUrl,
    }) as ReactElement<{ ref: RefObject<unknown> }>;
    element.props.ref.current = container;
    mocks.pendingEffects.splice(0).forEach((effect) => effect());
};

test("mounting a hidden slide outside the preload pair does not queue its video", () => {
    render(false);
    expect(mocks.create).toHaveBeenCalledOnce();
    expect(content.preload).not.toHaveBeenCalled();
    expect(mocks.queue).not.toHaveBeenCalled();
    render(true);
    expect(content.preload).toHaveBeenCalledOnce();
    expect(mocks.queue).toHaveBeenCalledOnce();
});

test("swiping away and back preserves the player and playback position", () => {
    render(true, true);
    content.video.currentTime = 0.5;
    render(false);
    expect(request.setPreloading).toHaveBeenLastCalledWith(false);
    expect(registration.setActive).toHaveBeenLastCalledWith(false);
    expect(request.cancel).not.toHaveBeenCalled();
    expect(content.destroy).not.toHaveBeenCalled();
    render(true, true);
    expect(request.setPreloading).toHaveBeenLastCalledWith(true);
    expect(mocks.create).toHaveBeenCalledOnce();
    expect(content.video.currentTime).toBe(0.5);
    expect(registration.setActive).toHaveBeenLastCalledWith(true);
});

test("activating the preloaded next slide reuses its player and load", () => {
    render(true);
    render(true, true);
    expect(mocks.create).toHaveBeenCalledOnce();
    expect(content.preload).toHaveBeenCalledOnce();
    expect(mocks.queue).toHaveBeenCalledOnce();
});

test("leaving the post releases its player and cancels its load", () => {
    render(true, true);
    render(false);
    unmount();
    expect(content.destroy).toHaveBeenCalledOnce();
    expect(request.cancel).toHaveBeenCalledOnce();
    expect(registration.unregister).toHaveBeenCalledOnce();
});

test("a preloaded slide shows its video frame as soon as it is decoded", () => {
    render(true);
    expect(content.video.poster).toBe("blob:cover");
    content.video.readyState = 2;
    content.video.dispatchEvent(new Event("loadeddata"));
    expect(content.video.poster).toBe("");
    expect(registration.setActive).toHaveBeenLastCalledWith(false);
    render(true, true);
    expect(content.video.poster).toBe("");
    expect(content.destroy).not.toHaveBeenCalled();
});

test("a late cover does not replace an already decoded video frame", () => {
    render(true, false, "");
    content.video.readyState = 2;
    content.video.dispatchEvent(new Event("loadeddata"));
    render(true, false, "blob:late-cover");
    expect(content.video.poster).toBe("");
});

test("swiping back keeps the paused frame and playback position", () => {
    render(true, true);
    content.video.readyState = 4;
    content.video.dispatchEvent(new Event("loadeddata"));
    content.video.currentTime = 0.5;
    render(false);
    render(true, true);
    expect(content.video.poster).toBe("");
    expect(content.video.currentTime).toBe(0.5);
    expect(mocks.create).toHaveBeenCalledOnce();
});

test("an emptied video restores its latest cover and removes listeners on unmount", () => {
    render(true);
    content.video.readyState = 2;
    content.video.dispatchEvent(new Event("loadeddata"));
    render(true, false, "blob:latest-cover");
    content.video.readyState = 0;
    content.video.dispatchEvent(new Event("emptied"));
    expect(content.video.poster).toBe("blob:latest-cover");
    unmount();
    content.video.readyState = 2;
    content.video.dispatchEvent(new Event("loadeddata"));
    expect(content.video.poster).toBe("blob:latest-cover");
});
