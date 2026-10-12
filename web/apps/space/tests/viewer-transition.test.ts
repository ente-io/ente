import { afterEach, expect, test, vi } from "vitest";
import {
    playViewerOpen,
    viewerOriginKey,
} from "../src/components/viewer-transition";

afterEach(() => vi.unstubAllGlobals());

test("tiles are matched by space and post", () => {
    expect(viewerOriginKey("space", 12)).toBe("space:12");
    expect(viewerOriginKey("space", 0)).toBe("space:0");
    expect(viewerOriginKey(undefined, 12)).toBeUndefined();
    expect(viewerOriginKey("space", undefined)).toBeUndefined();
});

const pendingFlight = () => {
    let resolveDecode!: () => void;
    let rejectDecode!: (error: Error) => void;
    const decoded = new Promise<void>((resolve, reject) => {
        resolveDecode = resolve;
        rejectDecode = reject;
    });
    const flyer = {
        style: {} as Record<string, string>,
        setAttribute: vi.fn(),
        append: vi.fn(),
        remove: vi.fn(),
    };
    const image = { style: {}, src: "", decode: () => decoded };
    const origin = {
        style: { opacity: "" },
        closest: () => null,
        getBoundingClientRect: () => ({
            left: 10,
            top: 20,
            width: 100,
            height: 100,
        }),
        querySelector: (selector: string) =>
            selector == "img[aria-hidden]"
                ? { currentSrc: "data:thumbnail" }
                : null,
    };
    vi.stubGlobal("document", {
        createElement: (tag: string) => (tag == "img" ? image : flyer),
    });
    vi.stubGlobal("window", {
        innerWidth: 390,
        innerHeight: 844,
        matchMedia: () => ({ matches: false }),
    });
    vi.stubGlobal("getComputedStyle", () => ({
        borderTopLeftRadius: "24px",
        borderTopRightRadius: "24px",
        borderBottomRightRadius: "0px",
        borderBottomLeftRadius: "0px",
    }));
    const requestFrame = vi.fn(() => 1);
    vi.stubGlobal("requestAnimationFrame", requestFrame);
    vi.stubGlobal("cancelAnimationFrame", vi.fn());
    const onLanded = vi.fn();
    const flight = playViewerOpen(
        { dataset: {}, prepend: vi.fn() } as unknown as HTMLElement,
        {
            origin: origin as unknown as HTMLElement,
            src: "full-photo",
            photo: { width: 200, height: 100 },
        },
        { x: 0, y: 100, w: 390, h: 195 },
        vi.fn(),
        onLanded,
    )!;
    return {
        flight,
        flyer,
        image,
        origin,
        requestFrame,
        resolveDecode,
        rejectDecode,
        onLanded,
    };
};

test("the tile stays visible until its flying thumbnail has decoded", async () => {
    const { flight, flyer, image, origin, requestFrame, resolveDecode } =
        pendingFlight();
    expect(image.src).toBe("data:thumbnail");
    expect(origin.style.opacity).toBe("");
    expect(flyer.style.visibility).toBe("hidden");
    expect(flight.current()).toBeUndefined();
    expect(requestFrame).not.toHaveBeenCalled();

    resolveDecode();
    await Promise.resolve();

    expect(origin.style.opacity).toBe("0");
    expect(flyer.style.visibility).toBe("");
    expect(flight.current()?.radii).toEqual([24, 24, 0, 0]);
    expect(requestFrame).toHaveBeenCalledOnce();
    flight.stop();
});

test("closing before decoding cannot hide the tile afterward", async () => {
    const { flight, flyer, origin, requestFrame, resolveDecode } =
        pendingFlight();
    flight.stop();
    resolveDecode();
    await Promise.resolve();

    expect(origin.style.opacity).toBe("");
    expect(flyer.remove).toHaveBeenCalledOnce();
    expect(requestFrame).not.toHaveBeenCalled();
});

test("a failed flyer leaves the tile visible and allows viewer handover", async () => {
    const { flight, origin, onLanded, rejectDecode } = pendingFlight();
    rejectDecode(new Error("decode failed"));
    await Promise.resolve();

    expect(origin.style.opacity).toBe("");
    expect(onLanded).toHaveBeenCalledOnce();
    flight.stop();
});
