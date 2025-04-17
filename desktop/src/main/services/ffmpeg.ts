import pathToFfmpeg from "ffmpeg-static";
import fs from "node:fs/promises";
import type { ZipItem } from "../../types/ipc";
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
    return pathToFfmpeg!.replace("app.asar", "app.asar.unpacked");
};

/**
 * A variant of {@link ffmpegExec} adapted to work with streams so that it can
 * handle the MP4 conversion of large video files.
 *
 * @param inputFilePath The path to a file on the user's local file system. This
 * is the video we want to convert.
 *
 * @param outputFilePath The path to a file on the user's local file system where
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

/**
 * A bespoke variant of {@link ffmpegExec} for generation of HLS playlists for
 * videos.
 *
 * See: [Note: Preview variant of videos]

 * @param inputFilePath The path to a file on the user's local file system. This
 * is the video we want to convert.
 *
 * @param outputPlaylistPath The path to a file on the user's local file system
 * where we should write the generated HLS playlist.
 *
 * @param outputVideoPath The path to a file on the user's local file system
 * where we should write the transcoded and encrypted video that the HLS
 * playlist refers to.
 */
export const ffmpegGenerateHLSPlaylist = async (
    inputFilePath: string,
    outputFilePath: string,
): Promise<void> => {
    // Current parameters
    //
    // - H264
    // - 720p width
    // - 2000kbps bitrate
    // - 30fps frame rate
    const command = [
        ffmpegPathPlaceholder,
        // Input file. We don't need any extra options that apply to the input file.
        "-i",
        inputPathPlaceholder,
        // The remaining options apply to the next file, `outputPathPlaceholder`.
        // ---
        // `-vf` creates a filter graph for the video stream.
        "-vf",
        // `-vf scale=720:-1` scales the video to 720p width, keeping aspect ratio.
        "scale=720:-1",
        // `-r 30` sets the frame rate to 30 fps.
        "-r",
        "30",
        // `-c:v libx264` sets the codec for the video stream to H264.
        "-c:v",
        "libx264",
        // `-b:v 2000k` sets the bitrate for the video stream.
        "-b:v",
        "2000k",
        // `-c:a aac -b:a 128k` converts the audio stream to 128k bit AAC.
        "-c:a",
        "aac",
        "-b:a",
        "128k",
        outputPathPlaceholder,
    ];

    const cmd = substitutePlaceholders(command, inputFilePath, outputFilePath);

    await execAsync(cmd);
};
