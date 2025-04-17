import { FFmpeg } from "@ffmpeg/ffmpeg";
import { newID } from "ente-base/id";
import log from "ente-base/log";
import { PromiseQueue } from "ente-utils/promise";
import {
    ffmpegPathPlaceholder,
    inputPathPlaceholder,
    outputPathPlaceholder,
} from "./constants";

/** Lazily initialized and loaded FFmpeg instance. */
let _ffmpeg: Promise<FFmpeg> | undefined;

/** Queue of in-flight requests. */
const _ffmpegTaskQueue = new PromiseQueue<Uint8Array>();

/**
 * Return the shared {@link FFmpeg} instance, lazily creating and loading it if
 * needed.
 */
const ffmpegLazy = (): Promise<FFmpeg> => (_ffmpeg ??= createFFmpeg());

const createFFmpeg = async () => {
    const ffmpeg = new FFmpeg();
    await ffmpeg.load({
        coreURL: "https://assets.ente.io/ffmpeg-core-0.12.10/ffmpeg-core.js",
        wasmURL: "https://assets.ente.io/ffmpeg-core-0.12.10/ffmpeg-core.wasm",
    });
    // This is too noisy to enable even during development. Uncomment to taste.
    // ffmpeg.on("log", (e) => log.debug(() => ["[ffmpeg]", e.message]));
    return ffmpeg;
};

/**
 * Run the given FFmpeg command using a Wasm FFmpeg running in a web worker.
 *
 * This is a sibling of {@link ffmpegExec} exposed by the desktop app in
 * `ipc.ts`. As a rough ballpark, currently the native FFmpeg integration in the
 * desktop app is 10-20x faster than the Wasm one.
 *
 * See: [Note: FFmpeg in Electron].
 *
 * @param command The FFmpeg command to execute.
 *
 * @param blob The input data on which to run the command, provided as a blob.
 *
 * @param outputFileExtension The extension of the (temporary) output file which
 * will be generated by the command.
 *
 * @returns The contents of the output file generated as a result of executing
 * {@link command} on {@link blob}.
 */
export const ffmpegExecWeb = async (
    command: string[],
    blob: Blob,
    outputFileExtension: string,
): Promise<Uint8Array> => {
    const ffmpeg = await ffmpegLazy();
    // Interleaving multiple ffmpeg.execs causes errors like
    //
    // >  "Out of bounds memory access (evaluating 'Module["_malloc"](len)')"
    //
    // So serialize them using a promise queue.
    return _ffmpegTaskQueue.add(() =>
        ffmpegExec(ffmpeg, command, outputFileExtension, blob),
    );
};

const ffmpegExec = async (
    ffmpeg: FFmpeg,
    command: string[],
    outputFileExtension: string,
    blob: Blob,
) => {
    const inputPath = newID("in_");
    const outputSuffix = outputFileExtension ? "." + outputFileExtension : "";
    const outputPath = newID("out_") + outputSuffix;

    const cmd = substitutePlaceholders(command, inputPath, outputPath);

    const inputData = new Uint8Array(await blob.arrayBuffer());

    // Exit status of the ffmpeg.exec invocation.
    // `0` if no error, `!= 0` if timeout (1) or error.
    let status: number | undefined;

    try {
        const startTime = Date.now();

        await ffmpeg.writeFile(inputPath, inputData);

        status = await ffmpeg.exec(cmd);
        if (status !== 0) {
            log.info(
                `[wasm] ffmpeg command failed with exit code ${status}: ${cmd.join(" ")}`,
            );
            throw new Error(`ffmpeg command failed with exit code ${status}`);
        }

        const result = await ffmpeg.readFile(outputPath);
        if (typeof result == "string") throw new Error("Expected binary data");

        const ms = Date.now() - startTime;
        log.debug(() => `[wasm] ffmpeg ${cmd.join(" ")} (${ms} ms)`);
        return result;
    } finally {
        try {
            await ffmpeg.deleteFile(inputPath);
        } catch (e) {
            log.error(`Failed to remove input ${inputPath}`, e);
        }
        try {
            await ffmpeg.deleteFile(outputPath);
        } catch (e) {
            // Output file might not even exist if the command did not succeed,
            // so only log on success.
            if (status === 0) {
                log.error(`Failed to remove output ${outputPath}`, e);
            }
        }
    }
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
        .filter((s) => s !== undefined);
