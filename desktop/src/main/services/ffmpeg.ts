import pathToFfmpeg from "ffmpeg-static";
import fs from "node:fs/promises";
import type { ZipItem } from "../../types/ipc";
import { ensure } from "../utils/common";
import { execAsync } from "../utils/electron";
import {
    deleteTempFileIgnoringErrors,
    makeFileForDataOrPathOrZipItem,
    makeTempFilePath,
} from "../utils/temp";

/* Ditto in the web app's code (used by the Wasm FFmpeg invocation). */
const ffmpegPathPlaceholder = "FFMPEG";
const inputPathPlaceholder = "INPUT";
const outputPathPlaceholder = "OUTPUT";

/**
 * Run a FFmpeg command
 *
 * [Note: FFmpeg in Electron]
 *
 * There is a Wasm build of FFmpeg, but that is currently 10-20 times slower
 * that the native build. That is slow enough to be unusable for our purposes.
 * https://ffmpegwasm.netlify.app/docs/performance
 *
 * So the alternative is to bundle a FFmpeg executable binary with our app. e.g.
 *
 *     yarn add fluent-ffmpeg ffmpeg-static ffprobe-static
 *
 * (we only use ffmpeg-static, the rest are mentioned for completeness' sake).
 *
 * Interestingly, Electron already bundles an binary FFmpeg library (it comes
 * from the ffmpeg fork maintained by Chromium).
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
    dataOrPathOrZipItem: Uint8Array | string | ZipItem,
    outputFileExtension: string,
): Promise<Uint8Array> => {
    const {
        path: inputFilePath,
        isFileTemporary: isInputFileTemporary,
        writeToTemporaryFile: writeToTemporaryInputFile,
    } = await makeFileForDataOrPathOrZipItem(dataOrPathOrZipItem);

    const outputFilePath = await makeTempFilePath(outputFileExtension);
    try {
        await writeToTemporaryInputFile();

        const cmd = substitutePlaceholders(
            command,
            inputFilePath,
            outputFilePath,
        );

        await execAsync(cmd);

        return await fs.readFile(outputFilePath);
    } finally {
        if (isInputFileTemporary)
            await deleteTempFileIgnoringErrors(inputFilePath);
        await deleteTempFileIgnoringErrors(outputFilePath);
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
 * At runtime, the FFmpeg binary is present in a path like (macOS example):
 * `ente.app/Contents/Resources/app.asar.unpacked/node_modules/ffmpeg-static/ffmpeg`
 */
const ffmpegBinaryPath = () => {
    // This substitution of app.asar by app.asar.unpacked is suggested by the
    // ffmpeg-static library author themselves:
    // https://github.com/eugeneware/ffmpeg-static/issues/16
    return ensure(pathToFfmpeg).replace("app.asar", "app.asar.unpacked");
};

/**
 * A variant of {@link ffmpegExec} adapted to work with streams so that it can
 * handle the MP4 conversion of large video files.
 *
 * See: [Note: Convert to MP4]

 * @param inputFilePath The path to a file on the user's local file system. This
 * is the video we want to convert.
 * @param inputFilePath The path to a file on the user's local file system where
 * we should write the converted MP4 video.
 */
export const ffmpegConvertToMP4 = async (
    inputFilePath: string,
    outputFilePath: string,
): Promise<void> => {
    const command = [
        ffmpegPathPlaceholder,
        "-i",
        inputPathPlaceholder,
        "-preset",
        "ultrafast",
        outputPathPlaceholder,
    ];

    const cmd = substitutePlaceholders(command, inputFilePath, outputFilePath);

    await execAsync(cmd);
};
