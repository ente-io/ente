import log from "@/next/log";
import QueueProcessor from "@ente/shared/utils/queueProcessor";
import { expose } from "comlink";
import {
    ffmpegPathPlaceholder,
    inputPathPlaceholder,
    outputPathPlaceholder,
} from "./constants";

// When we run tsc on CI, the line below errors out
//
// > Error: src/worker/ffmpeg.worker.ts(10,38): error TS2307: Cannot find module
//   'ffmpeg-wasm' or its corresponding type declarations.
//
// Building and running works fine. And this error does not occur when running
// tsc locally either.
//
// Of course, there is some misconfiguration, but we plan to move off our old
// fork and onto upstream ffmpeg-wasm, and the reason can be figured out then.
// For now, disable the error to allow the CI lint to complete.
//
// Note that we can't use @ts-expect-error since it doesn't error out when
// actually building!
//
// eslint-disable-next-line @typescript-eslint/ban-ts-comment, @typescript-eslint/prefer-ts-expect-error
// @ts-ignore
import { FFmpeg, createFFmpeg } from "ffmpeg-wasm";

export class DedicatedFFmpegWorker {
    private ffmpeg: FFmpeg;
    private ffmpegTaskQueue = new QueueProcessor<Uint8Array>();

    constructor() {
        this.ffmpeg = createFFmpeg({
            corePath: "/js/ffmpeg/ffmpeg-core.js",
            mt: false,
        });
    }

    /**
     * Execute a FFmpeg {@link command} on {@link blob}.
     *
     * This is a sibling of {@link ffmpegExec} exposed by the desktop app in
     * `ipc.ts`. See [Note: FFmpeg in Electron].
     */
    async exec(
        command: string[],
        blob: Blob,
        outputFileExtension: string,
    ): Promise<Uint8Array> {
        if (!this.ffmpeg.isLoaded()) await this.ffmpeg.load();

        const request = this.ffmpegTaskQueue.queueUpRequest(() =>
            ffmpegExec(this.ffmpeg, command, outputFileExtension, blob),
        );

        return await request.promise;
    }
}

expose(DedicatedFFmpegWorker, self);

const ffmpegExec = async (
    ffmpeg: FFmpeg,
    command: string[],
    outputFileExtension: string,
    blob: Blob,
) => {
    const inputPath = randomPrefix();
    const outputSuffix = outputFileExtension ? "." + outputFileExtension : "";
    const outputPath = randomPrefix() + outputSuffix;

    const cmd = substitutePlaceholders(command, inputPath, outputPath);

    const inputData = new Uint8Array(await blob.arrayBuffer());

    try {
        const startTime = Date.now();

        ffmpeg.FS("writeFile", inputPath, inputData);
        await ffmpeg.run(...cmd);

        const result = ffmpeg.FS("readFile", outputPath);

        const ms = Date.now() - startTime;
        log.debug(() => `[wasm] ffmpeg ${cmd.join(" ")} (${ms} ms)`);
        return result;
    } finally {
        try {
            ffmpeg.FS("unlink", inputPath);
        } catch (e) {
            log.error(`Failed to remove input ${inputPath}`, e);
        }
        try {
            ffmpeg.FS("unlink", outputPath);
        } catch (e) {
            log.error(`Failed to remove output ${outputPath}`, e);
        }
    }
};

/** Generate a random string suitable for being used as a file name prefix */
const randomPrefix = () => {
    const alphabet =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";

    let result = "";
    for (let i = 0; i < 10; i++)
        result += alphabet[Math.floor(Math.random() * alphabet.length)];
    return result;
};

const substitutePlaceholders = (
    command: string[],
    inputFilePath: string,
    outputFilePath: string,
) =>
    command
        .map((segment) => {
            if (segment == ffmpegPathPlaceholder) {
                return undefined;
            } else if (segment == inputPathPlaceholder) {
                return inputFilePath;
            } else if (segment == outputPathPlaceholder) {
                return outputFilePath;
            } else {
                return segment;
            }
        })
        .filter((c) => !!c);
