import type { ConversionOptions } from "mediabunny";
import { afterEach, beforeEach, expect, test, vi } from "vitest";

const mocks = vi.hoisted(() => ({
    init: vi.fn(),
    execute: vi.fn(),
    duration: vi.fn(),
    primaryVideo: vi.fn(),
    primaryAudio: vi.fn(),
    canEncodeAudio: vi.fn(),
    registerAacEncoder: vi.fn(),
    softwareFrames: vi.fn(),
    softwareExport: vi.fn(),
    frames: vi.fn(),
    log: vi.fn(),
    inputs: [] as { dispose: ReturnType<typeof vi.fn> }[],
    outputs: [] as {
        state: string;
        cancel: ReturnType<typeof vi.fn>;
        tracks: { metadata: { name?: string } }[];
    }[],
    conversions: [] as { state: string; cancel: ReturnType<typeof vi.fn> }[],
    sinkOptions: [] as { width: number; height: number }[],
    track: {
        computeDuration: vi.fn(),
        getDisplayWidth: vi.fn(),
        getDisplayHeight: vi.fn(),
        getFirstTimestamp: vi.fn(),
        hasHighDynamicRange: vi.fn(),
        canDecode: vi.fn(),
    },
    audio: {
        getCodec: vi.fn(),
        getNumberOfChannels: vi.fn(),
        getSampleRate: vi.fn(),
    },
}));
vi.mock("ente-base/log-web", () => ({ logToDisk: mocks.log }));
vi.mock("utils/thumbhash", () => ({ thumbHashBase64FromCanvas: () => "hash" }));
vi.mock("@mediabunny/aac-encoder", () => ({
    registerAacEncoder: mocks.registerAacEncoder,
}));
vi.mock("../src/utils/video-encoding/software", () => ({
    extractSoftwareVideoFrames: mocks.softwareFrames,
    transcodeSoftwareVideo: mocks.softwareExport,
}));
vi.mock("mediabunny", () => ({
    ALL_FORMATS: [],
    BlobSource: vi.fn(),
    BufferSource: vi.fn(),
    canEncodeAudio: mocks.canEncodeAudio,
    Input: class {
        constructor() {
            mocks.inputs.push(this);
        }
        dispose = vi.fn();
        getPrimaryVideoTrack = mocks.primaryVideo;
        getPrimaryAudioTrack = mocks.primaryAudio;
        computeDuration = mocks.duration;
    },
    BufferTarget: class {
        buffer = new Uint8Array([1, 2, 3]).buffer;
    },
    Mp4OutputFormat: vi.fn(),
    Quality: class {
        constructor(public options: unknown) {}
    },
    Output: class {
        state = "pending";
        tracks = [{ metadata: { name: "Private recording" } }];
        target: { buffer: ArrayBuffer };
        constructor(options: { target: { buffer: ArrayBuffer } }) {
            this.target = options.target;
            mocks.outputs.push(this);
        }
        cancel = vi.fn(() => {
            this.state = "canceled";
            return Promise.resolve();
        });
    },
    CanvasSink: class {
        constructor(
            _track: unknown,
            options: { width: number; height: number },
        ) {
            mocks.sinkOptions.push(options);
        }
        canvasesAtTimestamps = mocks.frames;
    },
    Conversion: { init: mocks.init },
}));

beforeEach(() => {
    vi.resetModules();
    vi.resetAllMocks();
    mocks.inputs.length = 0;
    mocks.outputs.length = 0;
    mocks.conversions.length = 0;
    mocks.sinkOptions.length = 0;
    mocks.primaryVideo.mockResolvedValue(mocks.track);
    mocks.primaryAudio.mockResolvedValue(mocks.audio);
    mocks.audio.getCodec.mockResolvedValue("aac");
    mocks.audio.getNumberOfChannels.mockResolvedValue(2);
    mocks.audio.getSampleRate.mockResolvedValue(48_000);
    mocks.canEncodeAudio.mockResolvedValue(true);
    mocks.softwareFrames.mockResolvedValue([
        {
            width: 90,
            height: 160,
            toBlob: (callback: BlobCallback) =>
                callback(new Blob(["cover"], { type: "image/png" })),
        },
    ]);
    mocks.softwareExport.mockResolvedValue(new Uint8Array([4, 5, 6]));
    vi.stubGlobal("navigator", {
        userAgent:
            "Mozilla/5.0 (iPhone; CPU iPhone OS 26_5 like Mac OS X) AppleWebKit/605.1.15 Version/26.5 Mobile Safari/604.1",
    });
    mocks.duration.mockResolvedValue(10);
    mocks.track.computeDuration.mockResolvedValue(10.833333);
    mocks.track.getDisplayWidth.mockResolvedValue(1080);
    mocks.track.getDisplayHeight.mockResolvedValue(1920);
    mocks.track.getFirstTimestamp.mockResolvedValue(0);
    mocks.track.hasHighDynamicRange.mockResolvedValue(false);
    mocks.track.canDecode.mockResolvedValue(true);
    mocks.execute.mockResolvedValue(undefined);
    mocks.frames.mockImplementation(function* (times: number[]) {
        for (const time of times)
            yield { canvas: { width: 90, height: 160, time } };
    });
    mocks.init.mockImplementation((options: ConversionOptions) => {
        let rejectExecution: (error: Error) => void = () => undefined;
        const conversion = {
            isValid: true,
            discardedTracks: [],
            state: "ready",
            execute: async () => {
                await Promise.race([
                    mocks.execute(options),
                    new Promise((_, reject) => {
                        rejectExecution = reject;
                    }),
                ]);
                conversion.state = "done";
                options.output.state = "finalized";
            },
            cancel: vi.fn(async () => {
                conversion.state = "canceled";
                rejectExecution(new Error("Conversion canceled"));
                await options.output.cancel();
            }),
        };
        mocks.conversions.push(conversion);
        return Promise.resolve(conversion);
    });
});
afterEach(() => {
    vi.useRealTimers();
    vi.unstubAllGlobals();
});

const file = () => new File(["video"], "private.mov");
const edit = { start: 1.125, end: 9.875, muted: false, coverTime: 1.125 };
const exporter = async () =>
    (await import("../src/utils/video-encoding/web")).transcodeVideoWeb;

test("exports the selected primary tracks without copying location or other source tags", async () => {
    expect(await (await exporter())(file(), edit)).toEqual(
        new Uint8Array([1, 2, 3]),
    );
    const options = mocks.init.mock.calls[0]![0] as ConversionOptions;
    expect(options).toMatchObject({
        tracks: "primary",
        trim: { start: 1.125, end: 9.875 },
        copy: { boundaryPolicy: "shrink" },
        tags: {},
        audio: { codec: "aac" },
    });
    expect(mocks.inputs[0]!.dispose).toHaveBeenCalled();
    expect(mocks.outputs[0]!.cancel).not.toHaveBeenCalled();
    expect(JSON.stringify(mocks.log.mock.calls)).not.toContain("private.mov");
});

test("remuxes the encoded packets within the trim to remove encoder padding", async () => {
    await (
        await exporter()
    )(file(), edit);
    expect(mocks.init.mock.calls[1]![0]).toMatchObject({
        tracks: "primary",
        trim: { start: 0, end: 8.75 },
        copy: { mode: "forced", boundaryPolicy: "shrink" },
        tags: {},
    });
    expect(mocks.inputs[1]!.dispose).toHaveBeenCalled();
    expect(mocks.outputs[1]!.tracks[0]!.metadata.name).toBeUndefined();
});

test("canceling the final packet copy disposes both inputs and permits another export", async () => {
    mocks.execute
        .mockResolvedValueOnce(undefined)
        .mockImplementationOnce(() => new Promise(() => undefined));
    const run = await exporter();
    const controller = new AbortController();
    const pending = run(file(), edit, controller.signal);
    const canceled = expect(pending).rejects.toMatchObject({
        name: "AbortError",
    });
    await vi.waitFor(() => expect(mocks.execute).toHaveBeenCalledTimes(2));
    controller.abort();
    await canceled;
    await run(file(), edit);
    expect(mocks.inputs[0]!.dispose).toHaveBeenCalled();
    expect(mocks.inputs[1]!.dispose).toHaveBeenCalled();
    expect(mocks.conversions[1]!.cancel).toHaveBeenCalledOnce();
});

test("bakes portrait orientation into even 1080p dimensions and renders HDR through sRGB", async () => {
    mocks.track.getDisplayWidth.mockResolvedValue(2160);
    mocks.track.getDisplayHeight.mockResolvedValue(3840);
    mocks.track.hasHighDynamicRange.mockResolvedValue(true);
    const draw = vi.fn();
    const context = { canvas: {} };
    const getContext = vi.fn(() => context);
    vi.stubGlobal("document", { createElement: () => ({ getContext }) });
    await (
        await exporter()
    )(file(), edit);
    const options = mocks.init.mock.calls[0]![0] as ConversionOptions;
    const configure = options.video as (
        track: unknown,
    ) => Promise<Record<string, unknown>>;
    const video = await configure(mocks.track);
    expect(video).toMatchObject({
        width: 1080,
        height: 1920,
        frameRate: 30,
        codec: "avc",
        allowTransformationMetadata: false,
    });
    expect(getContext).toHaveBeenCalledWith("2d", { colorSpace: "srgb" });
    expect((video.process as (sample: unknown) => unknown)({ draw })).toBe(
        context.canvas,
    );
    expect(draw).toHaveBeenCalledWith(context, 0, 0, 1080, 1920);
});

test("muting explicitly discards audio", async () => {
    await (
        await exporter()
    )(file(), { ...edit, muted: true });
    expect(mocks.init.mock.calls[0]![0]).toMatchObject({
        audio: { discard: true },
    });
});

test.each(["undecodable_source_codec", "no_encodable_target_codec"])(
    "rejects unsupported audio instead of silently publishing a muted video (%s)",
    async (reason) => {
        mocks.init.mockResolvedValueOnce({
            isValid: true,
            discardedTracks: [{ reason }],
            state: "ready",
            cancel: vi.fn(),
        });
        await expect((await exporter())(file(), edit)).rejects.toThrow(
            "can't export",
        );
        expect(mocks.execute).not.toHaveBeenCalled();
        expect(mocks.inputs[0]!.dispose).toHaveBeenCalled();
    },
);

test("rejects a file without video and releases the input", async () => {
    mocks.primaryVideo.mockResolvedValueOnce(null);
    await expect((await exporter())(file(), edit)).rejects.toThrow(
        "no readable video",
    );
    expect(mocks.init).not.toHaveBeenCalled();
    expect(mocks.inputs[0]!.dispose).toHaveBeenCalled();
});

test("canceling an active export closes the codecs and allows the next job to run", async () => {
    mocks.execute.mockImplementationOnce(() => new Promise(() => undefined));
    const run = await exporter();
    const controller = new AbortController();
    const pending = run(file(), edit, controller.signal);
    const canceled = expect(pending).rejects.toMatchObject({
        name: "AbortError",
    });
    await vi.waitFor(() => expect(mocks.execute).toHaveBeenCalledOnce());
    controller.abort();
    await canceled;
    expect(await run(file(), edit)).toEqual(new Uint8Array([1, 2, 3]));
    expect(mocks.conversions[0]!.cancel).toHaveBeenCalledOnce();
    expect(mocks.outputs[0]!.cancel).toHaveBeenCalled();
    expect(mocks.inputs[0]!.dispose).toHaveBeenCalled();
});

test("canceling a queued export returns promptly without canceling the active export", async () => {
    let finish!: () => void;
    mocks.execute.mockImplementationOnce(
        () =>
            new Promise<void>((resolve) => {
                finish = resolve;
            }),
    );
    const run = await exporter();
    const first = run(file(), edit);
    await vi.waitFor(() => expect(mocks.execute).toHaveBeenCalledOnce());
    const controller = new AbortController();
    const second = run(file(), edit, controller.signal);
    const canceled = expect(second).rejects.toMatchObject({
        name: "AbortError",
    });
    controller.abort();
    await canceled;
    expect(mocks.inputs).toHaveLength(1);
    expect(mocks.conversions[0]!.cancel).not.toHaveBeenCalled();
    finish();
    await first;
    await run(file(), edit);
    expect(mocks.inputs).toHaveLength(4);
    expect(mocks.execute).toHaveBeenCalledTimes(4);
});

test("a stalled conversion times out and releases the queue", async () => {
    vi.useFakeTimers();
    mocks.execute.mockImplementationOnce(() => new Promise(() => undefined));
    const run = await exporter();
    const pending = run(file(), edit);
    const timedOut = expect(pending).rejects.toMatchObject({
        name: "TimeoutError",
    });
    await vi.advanceTimersByTimeAsync(300_000);
    await timedOut;
    expect(await run(file(), edit)).toEqual(new Uint8Array([1, 2, 3]));
    expect(mocks.conversions[0]!.cancel).toHaveBeenCalledOnce();
});

test("a conversion failure releases its resources and permits retry", async () => {
    mocks.execute.mockRejectedValueOnce(new Error("Encoder failed"));
    const run = await exporter();
    await expect(run(file(), edit)).rejects.toThrow("Encoder failed");
    expect(mocks.outputs[0]!.cancel).toHaveBeenCalled();
    expect(mocks.inputs[0]!.dispose).toHaveBeenCalled();
    await expect(run(file(), edit)).resolves.toBeDefined();
});

test("reads oriented metadata without requiring a video decoder", async () => {
    mocks.track.canDecode.mockResolvedValue(false);
    const { determineVideoInfoWeb } =
        await import("../src/utils/video-encoding/web");
    expect(await determineVideoInfoWeb(file())).toEqual({
        duration: 10.833333,
        width: 1080,
        height: 1920,
    });
    expect(mocks.track.canDecode).not.toHaveBeenCalled();
    expect(mocks.inputs[0]!.dispose).toHaveBeenCalled();
});

test("extracts a batch of portrait thumbnails and clamps requests past the end", async () => {
    const { extractVideoFramesWeb } =
        await import("../src/utils/video-encoding/web");
    expect(await extractVideoFramesWeb(file(), [0, 3, 11], 160)).toHaveLength(
        3,
    );
    expect(mocks.sinkOptions[0]).toMatchObject({ width: 90, height: 160 });
    const times = mocks.frames.mock.calls[0]![0] as number[];
    expect(times.slice(0, 2)).toEqual([0, 3]);
    expect(times[2]).toBeCloseTo(10.832333, 6);
    expect(mocks.inputs[0]!.dispose).toHaveBeenCalled();
});

test("fails cleanly when the browser cannot decode a cover", async () => {
    mocks.track.canDecode.mockResolvedValue(false);
    const { extractVideoFramesWeb } =
        await import("../src/utils/video-encoding/web");
    await expect(extractVideoFramesWeb(file(), [0], 160)).rejects.toThrow(
        "can't preview",
    );
    expect(mocks.frames).not.toHaveBeenCalled();
    expect(mocks.inputs[0]!.dispose).toHaveBeenCalled();
    expect(mocks.softwareFrames).not.toHaveBeenCalled();
});

test("Firefox Android without VideoDecoder can prepare a cover and export an unmuted video", async () => {
    vi.stubGlobal("navigator", {
        userAgent:
            "Mozilla/5.0 (Android 16; Mobile; rv:144.0) Gecko/144.0 Firefox/144.0",
    });
    vi.stubGlobal("VideoDecoder", undefined);
    vi.stubGlobal("VideoEncoder", undefined);
    mocks.track.canDecode.mockImplementation(() =>
        Promise.resolve(typeof VideoDecoder !== "undefined"),
    );
    const { spaceVideoInfo, spaceVideoCover, prepareSpaceVideo } =
        await import("../src/utils/post-video");
    const source = file();
    expect((await spaceVideoInfo(source)).duration).toBeGreaterThan(10);
    expect((await spaceVideoCover(source, 0)).file.size).toBeGreaterThan(0);
    const result = await prepareSpaceVideo(source, edit);
    expect(result.video.file.type).toBe("video/mp4");
    expect(new Uint8Array(await result.video.file.arrayBuffer())).toEqual(
        new Uint8Array([4, 5, 6]),
    );
    expect(mocks.softwareFrames).toHaveBeenCalledTimes(2);
    expect(mocks.softwareExport).toHaveBeenCalledWith(
        source,
        edit,
        false,
        expect.any(AbortSignal),
    );
    expect(mocks.init).not.toHaveBeenCalled();
    expect(
        mocks.inputs.every((input) => input.dispose.mock.calls.length > 0),
    ).toBe(true);
});

test("a browser without a native video encoder uses the software export", async () => {
    vi.stubGlobal("navigator", {
        userAgent:
            "Mozilla/5.0 (X11; Linux x86_64) Gecko/20100101 Firefox/144.0",
    });
    const cancel = vi.fn();
    mocks.init.mockResolvedValueOnce({
        isValid: false,
        discardedTracks: [{ reason: "no_encodable_target_codec" }],
        state: "ready",
        cancel,
    });
    expect(await (await exporter())(file(), edit)).toEqual(
        new Uint8Array([4, 5, 6]),
    );
    expect(cancel).toHaveBeenCalled();
    expect(mocks.softwareExport).toHaveBeenCalledOnce();
});

test.each([
    "Mozilla/5.0 (iPhone) AppleWebKit/605.1.15 Version/26.5 Mobile Safari/604.1",
    "Mozilla/5.0 (iPhone) AppleWebKit/605.1.15 CriOS/144.0 Mobile Safari/604.1",
    "Mozilla/5.0 (iPhone) AppleWebKit/605.1.15 FxiOS/144.0 Mobile Safari/605.1.15",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 Version/26.5 Safari/605.1.15",
])(
    "WebKit never enters the full FFmpeg path when native decoding is unavailable: %s",
    async (userAgent) => {
        vi.stubGlobal("navigator", { userAgent });
        mocks.track.canDecode.mockResolvedValue(false);
        const { extractVideoFramesWeb, transcodeVideoWeb } =
            await import("../src/utils/video-encoding/web");
        await expect(extractVideoFramesWeb(file(), [0], 160)).rejects.toThrow(
            "can't preview",
        );
        await expect(transcodeVideoWeb(file(), edit)).rejects.toThrow(
            "can't decode",
        );
        expect(mocks.softwareFrames).not.toHaveBeenCalled();
        expect(mocks.softwareExport).not.toHaveBeenCalled();
    },
);

test("the supported iPhone path never imports either software fallback", async () => {
    vi.doMock("../src/utils/video-encoding/software", () => {
        throw new Error("Full FFmpeg must not load on iPhone");
    });
    vi.doMock("@mediabunny/aac-encoder", () => {
        throw new Error("AAC fallback must not load for passthrough audio");
    });
    try {
        const { extractVideoFramesWeb, transcodeVideoWeb } =
            await import("../src/utils/video-encoding/web");
        await expect(
            extractVideoFramesWeb(file(), [0], 160),
        ).resolves.toHaveLength(1);
        await expect(transcodeVideoWeb(file(), edit)).resolves.toEqual(
            new Uint8Array([1, 2, 3]),
        );
    } finally {
        vi.doMock("../src/utils/video-encoding/software", () => ({
            extractSoftwareVideoFrames: mocks.softwareFrames,
            transcodeSoftwareVideo: mocks.softwareExport,
        }));
        vi.doMock("@mediabunny/aac-encoder", () => ({
            registerAacEncoder: mocks.registerAacEncoder,
        }));
    }
});

test.each(["opus", "vorbis", "pcm-s16"])(
    "registers software AAC before converting unmuted %s when native AAC is unavailable",
    async (codec) => {
        vi.stubGlobal("navigator", {
            userAgent:
                "Mozilla/5.0 (X11; Linux x86_64) Gecko/20100101 Firefox/144.0",
        });
        mocks.audio.getCodec.mockResolvedValue(codec);
        mocks.canEncodeAudio.mockResolvedValue(false);
        await expect((await exporter())(file(), edit)).resolves.toBeDefined();
        expect(mocks.canEncodeAudio).toHaveBeenCalledWith(
            "aac",
            expect.objectContaining({
                numberOfChannels: 2,
                sampleRate: 48_000,
            }),
        );
        expect(mocks.registerAacEncoder).toHaveBeenCalledOnce();
        expect(
            mocks.registerAacEncoder.mock.invocationCallOrder[0],
        ).toBeLessThan(mocks.init.mock.invocationCallOrder[0]!);
        expect(mocks.init.mock.calls[0]![0]).toMatchObject({
            audio: { codec: "aac" },
        });
        expect(mocks.softwareExport).not.toHaveBeenCalled();
    },
);

test("uses native AAC when supported and preserves AAC input without requiring an encoder", async () => {
    mocks.audio.getCodec.mockResolvedValueOnce("opus");
    await (
        await exporter()
    )(file(), edit);
    expect(mocks.canEncodeAudio).toHaveBeenCalledOnce();
    expect(mocks.registerAacEncoder).not.toHaveBeenCalled();
    mocks.canEncodeAudio.mockClear().mockResolvedValue(false);
    await (
        await exporter()
    )(file(), edit);
    expect(mocks.canEncodeAudio).not.toHaveBeenCalled();
    expect(mocks.registerAacEncoder).not.toHaveBeenCalled();
});

test("muted and silent videos do not load an AAC encoder", async () => {
    mocks.audio.getCodec.mockResolvedValue("opus");
    mocks.canEncodeAudio.mockResolvedValue(false);
    await (
        await exporter()
    )(file(), { ...edit, muted: true });
    mocks.primaryAudio.mockResolvedValue(null);
    await (
        await exporter()
    )(file(), edit);
    expect(mocks.canEncodeAudio).not.toHaveBeenCalled();
    expect(mocks.registerAacEncoder).not.toHaveBeenCalled();
});
