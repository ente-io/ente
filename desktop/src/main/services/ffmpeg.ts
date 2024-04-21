import pathToFfmpeg from "ffmpeg-static";
import fs from "node:fs/promises";
import { withTimeout } from "../utils";
import { execAsync } from "../utils-electron";
import { deleteTempFile, makeTempFilePath } from "../utils-temp";

const ffmpegPathPlaceholder = "FFMPEG";
const inputPathPlaceholder = "INPUT";
const outputPathPlaceholder = "OUTPUT";

/**
 * Run a ffmpeg command
 *
 * [Note: ffmpeg in Electron]
 *
 * There is a wasm build of ffmpeg, but that is currently 10-20 times slower
 * that the native build. That is slow enough to be unusable for our purposes.
 * https://ffmpegwasm.netlify.app/docs/performance
 *
 * So the alternative is to bundle a ffmpeg binary with our app. e.g.
 *
 *     yarn add fluent-ffmpeg ffmpeg-static ffprobe-static
 *
 * (we only use ffmpeg-static, the rest are mentioned for completeness' sake).
 *
 * Interestingly, Electron already bundles an ffmpeg library (it comes from the
 * ffmpeg fork maintained by Chromium).
 * https://chromium.googlesource.com/chromium/third_party/ffmpeg
 * https://stackoverflow.com/questions/53963672/what-version-of-ffmpeg-is-bundled-inside-electron
 *
 * This can be found in (e.g. on macOS) at
 *
 *     $ file ente.app/Contents/Frameworks/Electron\ Framework.framework/Versions/Current/Libraries/libffmpeg.dylib
 *     .../libffmpeg.dylib: Mach-O 64-bit dynamically linked shared library arm64
 *
 * But I'm not sure if our code is supposed to be able to use it, and how.
 */
export const ffmpegExec = async (
    command: string[],
    inputDataOrPath: Uint8Array | string,
    outputFileName: string,
    timeoutMS: number,
): Promise<Uint8Array> => {
    // TODO (MR): This currently copies files for both input and output. This
    // needs to be tested extremely large video files when invoked downstream of
    // `convertToMP4` in the web code.

    let inputFilePath: string;
    let isInputFileTemporary: boolean;
    if (typeof inputDataOrPath == "string") {
        inputFilePath = inputDataOrPath;
        isInputFileTemporary = false;
    } else {
        inputFilePath = await makeTempFilePath("input" /* arbitrary */);
        isInputFileTemporary = true;
        await fs.writeFile(inputFilePath, inputDataOrPath);
    }

    let outputFilePath: string | undefined;
    try {
        outputFilePath = await makeTempFilePath(outputFileName);

        const cmd = substitutePlaceholders(
            command,
            inputFilePath,
            outputFilePath,
        );

        if (timeoutMS) await withTimeout(execAsync(cmd), 30 * 1000);
        else await execAsync(cmd);

        return fs.readFile(outputFilePath);
    } finally {
        if (isInputFileTemporary) await deleteTempFile(inputFilePath);
        if (outputFilePath) await deleteTempFile(outputFilePath);
    }
};

const substitutePlaceholders = (
    command: string[],
    inputFilePath: string,
    outputFilePath: string,
) =>
    command.map((segment) => {
        if (segment == ffmpegPathPlaceholder) {
            return ffmpegBinaryPath();
        } else if (segment == inputPathPlaceholder) {
            return inputFilePath;
        } else if (segment == outputPathPlaceholder) {
            return outputFilePath;
        } else {
            return segment;
        }
    });

/**
 * Return the path to the `ffmpeg` binary.
 *
 * At runtime, the ffmpeg binary is present in a path like (macOS example):
 * `ente.app/Contents/Resources/app.asar.unpacked/node_modules/ffmpeg-static/ffmpeg`
 */
const ffmpegBinaryPath = () => {
    // This substitution of app.asar by app.asar.unpacked is suggested by the
    // ffmpeg-static library author themselves:
    // https://github.com/eugeneware/ffmpeg-static/issues/16
    return pathToFfmpeg.replace("app.asar", "app.asar.unpacked");
};
