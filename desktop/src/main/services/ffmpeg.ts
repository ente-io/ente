import pathToFfmpeg from "ffmpeg-static";
import { randomBytes } from "node:crypto";
import fs from "node:fs/promises";
import path from "node:path";
import type { ZipItem } from "../../types/ipc";
import log from "../log";
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

export interface FFmpegGenerateHLSPlaylistAndSegmentsResult {
    playlistPath: string;
    videoPath: string;
}

/**
 * A bespoke variant of {@link ffmpegExec} for generation of HLS playlists for
 * videos.
 *
 * See: [Note: Preview variant of videos]

 * @param inputFilePath The path to a file on the user's local file system. This
 * is the video we want to convert.
 *
 * @param outputPathPrefix The path to unique, unused and temporary prefix on
 * the user's local file system - we should write the generated HLS playlist and
 * video segments under this prefix.
 *
 * @returns The paths to two files on the user's local file system - one
 * containing the generated HLS playlist, and the other containing the
 * transcoded and encrypted video segments that the HLS playlist refers to.
 */
export const ffmpegGenerateHLSPlaylistAndSegments = async (
    inputFilePath: string,
    outputPathPrefix: string,
): Promise<FFmpegGenerateHLSPlaylistAndSegmentsResult> => {
    // We want the generated playlist to refer to the chunks as "output.ts".
    //
    // So we arrange things accordingly: We use the `outputPathPrefix` as our
    // working directory, and then ask ffmpeg to generate a playlist with the
    // name "output.m3u8".
    //
    // ffmpeg will automatically place the segments in a file with the same base
    // name as the playlist, but with a ".ts" extension. Since we use the
    // "single_file" option, all the segments will be placed in the same ".ts"
    // file, which will be named "output.ts".

    await fs.mkdir(outputPathPrefix);

    const playlistPath = path.join(outputPathPrefix, "output.m3u8");
    const videoPath = path.join(outputPathPrefix, "output.ts");

    // Generate a cryptographically secure random key (16 bytes).
    const keyBytes = randomBytes(16);
    const keyB64 = keyBytes.toString("base64");

    // Convert it to a data: URI that will be added to the playlist.
    const keyURI = `data:text/plain;base64,${keyB64}`;

    // Determine two paths - one where we will write the key itself, and where
    // we will write the "key info" that provides ffmpeg the `keyURI` and the
    // `keyPath;.
    const keyPath = playlistPath + ".key";
    const keyInfoPath = playlistPath + ".key-info";

    // Generate a "key info":
    //
    // - the first line specifies the key URI that is written into the playlist.
    // - the second line specifies the path to the local filesystem file from
    //   where ffmpeg should read the key.
    const keyInfo = [keyURI, keyPath].join("\n");

    // Current parameters
    //
    // - H264
    // - 720p width
    // - 2000kbps bitrate
    // - 30fps frame rate
    const command = [
        ffmpegBinaryPath(),

        // Input file. We don't need any extra options that apply to the input file.
        "-i",
        inputFilePath,

        // The remaining options apply to the next output file (`playlistPath`).
        //
        // ---
        /*
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
        */
        // Generate a HLS playlist.
        ["-f", "hls"],
        // Place all the video segments within the same .ts file (with the same
        // path as the playlist file but with a ".ts" extension).
        ["-hls_flags", "single_file"],
        // Encrypt the playlist.
        ["-hls_enc", "1"],
        // Tell ffmpeg where to find the key, and the URI for the key to write
        // into the generated playlist.
        ["-hls_key_info_file", keyInfoPath],
        // Output path where the playlist should be generated.
        playlistPath,
    ].flat();

    try {
        // Write the key and the keyInfo to their desired paths.
        await Promise.all([
            fs.writeFile(keyPath, keyBytes),
            fs.writeFile(keyInfoPath, keyInfo, { encoding: "utf8" }),
        ]);

        // Run the ffmpeg command to generate the HLS playlist and segments.
        //
        // Note: Depending on the size of the input file, this may take long!
        await execAsync(command);
    } catch (e) {
        log.error("HLS generation failed", e);
        await Promise.all([
            deleteTempFileIgnoringErrors(playlistPath),
            deleteTempFileIgnoringErrors(videoPath),
        ]);
    } finally {
        await Promise.all([
            deleteTempFileIgnoringErrors(keyInfoPath),
            deleteTempFileIgnoringErrors(keyPath),
        ]);
    }

    return { playlistPath, videoPath };
};
