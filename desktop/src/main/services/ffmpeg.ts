import pathToFfmpeg from "ffmpeg-static";
import { randomBytes } from "node:crypto";
import fs from "node:fs/promises";
import path from "node:path";
import type { ZipItem } from "../../types/ipc";
import log from "../log";
import { execAsync } from "../utils/electron";
import {
    deleteTempFileIgnoringErrors,
    makeFileForDataOrStreamOrPathOrZipItem,
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
    } = await makeFileForDataOrStreamOrPathOrZipItem(dataOrPathOrZipItem);

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
    dimensions: { width: number; height: number };
    videoSize: number;
}

/**
 * A bespoke variant of {@link ffmpegExec} for generation of HLS playlists for
 * videos.
 *
 * See: [Note: Preview variant of videos]

 * @param inputFilePath The path to a file on the user's local file system. This
 * is the video we want to generate an streamable HLS playlist for.
 *
 * @param outputPathPrefix The path to unique, unused and temporary prefix on
 * the user's local file system. This function will write the generated HLS
 * playlist and video segments under this prefix.
 *
 * @returns The paths to two files on the user's local file system - one
 * containing the generated HLS playlist, and the other containing the
 * transcoded and encrypted video segments that the HLS playlist refers to.
 */
export const ffmpegGenerateHLSPlaylistAndSegments = async (
    inputFilePath: string,
    outputPathPrefix: string,
): Promise<FFmpegGenerateHLSPlaylistAndSegmentsResult> => {
    // [Note: Tonemapping HDR to HD]
    //
    // BT.709 ("HD") is a standard that describes things like how color is
    // encoded, the range of values, and their "meaning" - i.e. how to map the
    // values in the video to the pixels on the screen.
    //
    // It is not the only such standard, there are three common examples:
    //
    // - BT.601 ("Standard-Definition" or SD)
    // - BT.709 ("High-Definition" or HD)
    // - BT.2020 ("Ultra-High-Definition" or UHD, aka HDR^).
    //
    // ^ HDR ("High-Dynamic-Range") is an addendum to BT.2020, but for our
    //   purpose here we can treat it as as alias.
    //
    // BT.709 is the most common amongst these for older files out stored on
    // computers, and they conform mostly to the standard (one notable exception
    // is that the BT.709 standard also recommends using the yuv422p pixel
    // format, but de facto yuv420p is used because many video players only
    // support yuv420p).
    //
    // Since BT.709 is the most widely supported standard, we use it when
    // generating the HLS playlist so to allow playback across the widest
    // possible hardware/OS/browser combinations.
    //
    // If we convert HDR to HD without naively, then the colors look washed out
    // compared to the original. To resolve this, we use a ffmpeg filterchain
    // that uses the tonemap filter.
    //
    // However applying this tonemap to videos that are already HD leads to a
    // brightness drop. So we conditionally apply this filter chain only if the
    // colorspace is not already BT.709.
    //
    // Reference:
    // - https://trac.ffmpeg.org/wiki/colorspace
    const isBT709 = await detectIsBT709(inputFilePath);

    // We want the generated playlist to refer to the chunks as "output.ts".
    //
    // So we arrange things accordingly: We use the `outputPathPrefix` as our
    // working directory, and then ask ffmpeg to generate a playlist with the
    // name "output.m3u8".
    //
    // ffmpeg will automatically place the segments in a file with the same base
    // name as the playlist, but with a ".ts" extension. And since we use the
    // "single_file" option, all the segments will be placed in a file named
    // "output.ts".

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

    // Overview:
    //
    // - H.264 video HD 720p 30fps.
    // - AAC audio 128kbps.
    // - Encrypted HLS playlist with a single file containing all the chunks.
    //
    // Reference:
    // - `man ffmpeg-all`
    // - https://trac.ffmpeg.org/wiki/Encode/H.264
    //
    const command = [
        ffmpegBinaryPath(),
        // Reduce the amount of output lines we have to parse.
        ["-hide_banner"],
        // Input file. We don't need any extra options that apply to the input file.
        "-i",
        inputFilePath,
        // The remaining options apply to the next output file (`playlistPath`).
        //
        // ---
        //
        // `-vf` creates a filter graph for the video stream. This is a string
        // of the form `filter1=key=value:key=value.filter2=key=value`, that is,
        // a comma separated list of filters chained together.
        [
            "-vf",
            [
                // Scales the video to maximum 720p height, keeping aspect
                // ratio, and keeping the calculated dimension divisible by 2
                // (some of the other operations require an even pixel count).
                "scale=-2:720",
                // Convert the video to a constant 30 fps, duplicating or
                // dropping frames as necessary.
                "fps=30",
                // If the video is not in the HD color space (bt709), convert
                // it. Before conversion, tone map colors so that they work the
                // same across the change in the dyamic range.
                //
                // 1. The tonemap filter only works linear light, so we first
                //    use zscale with transfer=linear to linearize the input.
                //
                // 2. Then we use the tonemap, with the hable option that is
                //    best for preserving details. desat=0 turns off the default
                //    desaturation.
                //
                // 3. Use zscale again to "convert to BT.709" by asking it to
                //    set the all three of color primaries, transfer
                //    characteristics and colorspace matrix to 709 (Note: the
                //    constants specified in the tonemap filter help do not
                //    include the "bt" prefix)
                //
                // See: https://ffmpeg.org/ffmpeg-filters.html#tonemap-1
                //
                // See: [Note: Tonemapping HDR to HD]
                isBT709
                    ? []
                    : [
                          "zscale=transfer=linear",
                          "tonemap=tonemap=hable:desat=0",
                          "zscale=primaries=709:transfer=709:matrix=709",
                      ],
                // Output using the most widely supported pixel format: 8-bit
                // YUV planar color space with 4:2:0 chroma subsampling.
                "format=yuv420p",
            ]
                .flat()
                .join(","),
        ],
        // Video codec H.264
        //
        // - `-c:v libx264` converts the video stream to use the H.264 codec.
        //
        // - We don't supply a bitrate, instead it uses the default CRF ("23")
        //   as recommended in the ffmpeg trac.
        //
        // - We don't supply a preset, it'll use the default ("medium")
        ["-c:v", "libx264"],
        // Audio codec AAC
        //
        // - `-c:a aac` converts the audio stream to use the AAC codec
        //
        // - We don't supply a bitrate, it'll use the AAC default 128k bps.
        ["-c:a", "aac"],
        // Generate a HLS playlist.
        ["-f", "hls"],
        // Tell ffmpeg where to find the key, and the URI for the key to write
        // into the generated playlist. Implies "-hls_enc 1".
        ["-hls_key_info_file", keyInfoPath],
        // Generate as many playlist entries as needed (default limit is 5).
        ["-hls_list_size", "0"],
        // Place all the video segments within the same .ts file (with the same
        // path as the playlist file but with a ".ts" extension).
        ["-hls_flags", "single_file"],
        // Output path where the playlist should be generated.
        playlistPath,
    ].flat();

    let dimensions: ReturnType<typeof detectVideoDimensions>;
    let videoSize: number;

    try {
        // Write the key and the keyInfo to their desired paths.
        await Promise.all([
            fs.writeFile(keyPath, keyBytes),
            fs.writeFile(keyInfoPath, keyInfo, { encoding: "utf8" }),
        ]);

        // Run the ffmpeg command to generate the HLS playlist and segments.
        //
        // Note: Depending on the size of the input file, this may take long!
        const { stderr: conversionStderr } = await execAsync(command);

        // Determine the dimensions of the generated video from the stderr
        // output produced by ffmpeg during the conversion.
        dimensions = detectVideoDimensions(conversionStderr);

        // Find the size of the generated video segments by reading the size of
        // the generated .ts file.
        videoSize = await fs.stat(videoPath).then((st) => st.size);
    } catch (e) {
        log.error("HLS generation failed", e);
        await Promise.all([
            deleteTempFileIgnoringErrors(playlistPath),
            deleteTempFileIgnoringErrors(videoPath),
        ]);
        throw e;
    } finally {
        await Promise.all([
            deleteTempFileIgnoringErrors(keyInfoPath),
            deleteTempFileIgnoringErrors(keyPath),
            // ffmpeg writes a /path/output.ts.tmp, clear it out too.
            deleteTempFileIgnoringErrors(videoPath + ".tmp"),
        ]);
    }

    return { playlistPath, videoPath, dimensions, videoSize };
};

/**
 * A regex that matches the first line of the form
 *
 *     Stream #0:0: Video: h264 (High 10) ([27][0][0][0] / 0x001B), yuv420p10le(tv, bt2020nc/bt2020/arib-std-b67), 1920x1080, 30 fps, 30 tbr, 90k tbn
 *
 * The part after Video: is the first capture group.
 */
const videoStreamLineRegex = /Stream #.+: Video:(.+)\n/;

/** {@link videoStreamLineRegex}, but global. */
const videoStreamLinesRegex = /Stream #.+: Video:(.+)\n/g;

/**
 * A regex that matches <digits>x<digits> pair preceded by a space and followed
 * by a trailing comma. See {@link videoStreamLineRegex} for the context in
 * which it is used.
 */
const videoDimensionsRegex = / (\d+)x(\d+),/;

/**
 * Heuristically determine if the given video uses the BT.709 colorspace.
 *
 * This function tries to determine the input colorspace by scanning the ffmpeg
 * info output for the video stream line, and checking if it contains the string
 * "bt709". See: [Note: Parsing CLI output might break on ffmpeg updates].
 */
const detectIsBT709 = async (inputFilePath: string) => {
    const videoInfo = await pseudoFFProbeVideo(inputFilePath);
    const videoStreamLine = videoStreamLineRegex.exec(videoInfo)?.at(1);
    return !!videoStreamLine?.includes("bt709");
};

/**
 * Heuristically detect the dimensions of the given video from the log output of
 * the ffmpeg invocation during the HLS playlist generation.
 *
 * This function tries to determine the width and height of the generated video
 * from the output log written by ffmpeg on its stderr during the generation
 * process, scanning it for the last video stream line, and trying to match a
 * "<digits>x<digits>" regex.
 *
 * See: [Note: Parsing CLI output might break on ffmpeg updates].
 */
const detectVideoDimensions = (conversionStderr: string) => {
    // There is a nicer way to do it - by running `pseudoFFProbeVideo` on the
    // generated playlist. However, that playlist includes a data URL that
    // specifies the encryption info, and ffmpeg refuses to read that unless we
    // specify the "-allowed_extensions ALL" or something to that effect.
    //
    // Unfortunately, our current ffmpeg binary (5.x) does not support that
    // option. So we instead parse the conversion output itself.
    //
    // This is also nice, since it saves on an extra ffmpeg invocation. But we
    // now need to be careful to find the right video stream line, since the
    // conversion output includes both the input and output video stream lines.
    //
    // To match the right (output) video stream line, we use a global regex, and
    // use the last match since that'd correspond to the single video stream
    // written in the output.
    const videoStreamLine = Array.from(
        conversionStderr.matchAll(videoStreamLinesRegex),
    )
        .at(-1) /* Last Stream...: Video: line in the output */
        ?.at(1); /* First capture group */
    if (videoStreamLine) {
        const [, ws, hs] = videoDimensionsRegex.exec(videoStreamLine) ?? [];
        if (ws && hs) {
            const w = parseInt(ws);
            const h = parseInt(hs);
            if (w && h) {
                return { width: w, height: h };
            }
        }
    }
    throw new Error(
        `Unable to detect video dimensions from stream line [${videoStreamLine ?? ""}]`,
    );
};

/**
 * We don't have the ffprobe binary at hand, so we make do by grepping the log
 * output of ffmpeg.
 *
 * > [Note: Parsing CLI output might break on ffmpeg updates]
 * >
 * > Needless to say, while this works currently, this is liable to break in the
 * > future. So if something stops working after updating ffmpeg, look here!
 *
 * @returns the stderr of ffmpeg after running it on the input file. The exact
 * command we run is:
 *
 *     ffmpeg -i in.mov -an -frames:v 0 -f null - 2>info.txt
 *
 * And the returned string is the contents of the `info.txt` thus produced.
 */
const pseudoFFProbeVideo = async (inputFilePath: string) => {
    const command = [
        ffmpegPathPlaceholder,
        // Reduce the amount of output lines we have to parse.
        ["-hide_banner"],
        ["-i", inputPathPlaceholder],
        "-an",
        ["-frames:v", "0"],
        ["-f", "null"],
        "-",
    ].flat();

    const cmd = substitutePlaceholders(command, inputFilePath, /* NA */ "");

    const { stderr } = await execAsync(cmd);

    return stderr;
};
