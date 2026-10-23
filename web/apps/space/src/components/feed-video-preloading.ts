interface VideoLoad {
    element: HTMLElement;
    load: (signal: AbortSignal) => Promise<string>;
    controller: AbortController;
    start: () => void;
    resolve: (url: string) => void;
    reject: (error: unknown) => void;
}

const queued = new Set<VideoLoad>();
let inFlight = 0;
let frame: number | undefined;
let foreground: VideoLoad | undefined;

const distance = ({ element }: VideoLoad) => {
    const rect = element.getBoundingClientRect();
    const post = element.closest("article")!.getBoundingClientRect();
    return (
        Math.max(0, rect.top - window.innerHeight, -rect.bottom) +
        Math.abs(rect.left - post.left)
    );
};

const schedule = () => {
    if (!queued.size || inFlight >= 3) return;
    frame ??= requestAnimationFrame(() => {
        frame = undefined;
        for (const request of queued) {
            if (!request.element.isConnected) {
                queued.delete(request);
                if (foreground == request) foreground = undefined;
                request.reject(
                    new DOMException("Video preload canceled", "AbortError"),
                );
            }
        }
        const next = [...queued].sort(
            (a, b) =>
                Number(b == foreground) - Number(a == foreground) ||
                distance(a) - distance(b),
        );
        for (const request of next) {
            if (inFlight >= (request == foreground ? 3 : 2)) continue;
            queued.delete(request);
            inFlight++;
            request.start();
            void (async () => {
                try {
                    request.resolve(
                        await request.load(request.controller.signal),
                    );
                } catch (error) {
                    request.reject(error);
                } finally {
                    inFlight--;
                    if (foreground == request) foreground = undefined;
                    schedule();
                }
            })();
        }
    });
};

export const queueFeedVideoLoad = (
    element: HTMLElement,
    load: VideoLoad["load"],
    signal?: AbortSignal,
) => {
    const controller = new AbortController();
    let start: () => void;
    const started = new Promise<void>((resolve) => {
        start = resolve;
    });
    let request: VideoLoad;
    const promise = new Promise<string>((resolve, reject) => {
        request = { element, load, controller, start, resolve, reject };
        queued.add(request);
        schedule();
    });
    const cancel = () => {
        controller.abort();
        if (foreground == request) foreground = undefined;
        if (!queued.delete(request)) return;
        request.reject(controller.signal.reason);
        if (!queued.size && frame != undefined) {
            cancelAnimationFrame(frame);
            frame = undefined;
        }
    };
    if (signal?.aborted) cancel();
    else signal?.addEventListener("abort", cancel, { once: true });
    return {
        promise: promise.finally(() =>
            signal?.removeEventListener("abort", cancel),
        ),
        prioritize: () => {
            if (queued.has(request)) {
                foreground = request;
                schedule();
            }
            return Promise.race([started, promise.then(() => undefined)]);
        },
        deprioritize: () => {
            if (foreground == request) foreground = undefined;
        },
        cancel,
    };
};
