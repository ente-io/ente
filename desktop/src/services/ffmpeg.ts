import pathToFfmpeg from "ffmpeg-static";
import { existsSync } from "node:fs";
import fs from "node:fs/promises";
import { CustomErrors } from "../constants/errors";
import { writeStream } from "../main/fs";
import log from "../main/log";
import { execAsync } from "../main/util";
import { ElectronFile } from "../types/ipc";
import { generateTempFilePath, getTempDirPath } from "../utils/temp";

const INPUT_PATH_PLACEHOLDER = "INPUT";
const FFMPEG_PLACEHOLDER = "FFMPEG";
const OUTPUT_PATH_PLACEHOLDER = "OUTPUT";

/**
 * Run a ffmpeg command
 *
 * [Note: FFMPEG in Electron]
 *
 * There is a wasm build of FFMPEG, but that is currently 10-20 times slower
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
 * I'm not sure if our code is supposed to be able to use it, and how.
 */
export async function runFFmpegCmd(
    cmd: string[],
    inputFile: File | ElectronFile,
    outputFileName: string,
    dontTimeout?: boolean,
) {
    let inputFilePath = null;
    let createdTempInputFile = null;
    try {
        if (!existsSync(inputFile.path)) {
            const tempFilePath = await generateTempFilePath(inputFile.name);
            await writeStream(tempFilePath, await inputFile.stream());
            inputFilePath = tempFilePath;
            createdTempInputFile = true;
        } else {
            inputFilePath = inputFile.path;
        }
        const outputFileData = await runFFmpegCmd_(
            cmd,
            inputFilePath,
            outputFileName,
            dontTimeout,
        );
        return new File([outputFileData], outputFileName);
    } finally {
        if (createdTempInputFile) {
            await deleteTempFile(inputFilePath);
        }
    }
}

export async function runFFmpegCmd_(
    cmd: string[],
    inputFilePath: string,
    outputFileName: string,
    dontTimeout = false,
) {
    let tempOutputFilePath: string;
    try {
        tempOutputFilePath = await generateTempFilePath(outputFileName);

        cmd = cmd.map((cmdPart) => {
            if (cmdPart === FFMPEG_PLACEHOLDER) {
                return ffmpegBinaryPath();
            } else if (cmdPart === INPUT_PATH_PLACEHOLDER) {
                return inputFilePath;
            } else if (cmdPart === OUTPUT_PATH_PLACEHOLDER) {
                return tempOutputFilePath;
            } else {
                return cmdPart;
            }
        });

        if (dontTimeout) {
            await execAsync(cmd);
        } else {
            await promiseWithTimeout(execAsync(cmd), 30 * 1000);
        }

        if (!existsSync(tempOutputFilePath)) {
            throw new Error("ffmpeg output file not found");
        }
        const outputFile = await fs.readFile(tempOutputFilePath);
        return new Uint8Array(outputFile);
    } catch (e) {
        log.error("FFMPEG command failed", e);
        throw e;
    } finally {
        await deleteTempFile(tempOutputFilePath);
    }
}

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

export async function writeTempFile(fileStream: Uint8Array, fileName: string) {
    const tempFilePath = await generateTempFilePath(fileName);
    await fs.writeFile(tempFilePath, fileStream);
    return tempFilePath;
}

export async function deleteTempFile(tempFilePath: string) {
    const tempDirPath = await getTempDirPath();
    if (!tempFilePath.startsWith(tempDirPath))
        log.error("Attempting to delete a non-temp file ${tempFilePath}");
    await fs.rm(tempFilePath, { force: true });
}

const promiseWithTimeout = async <T>(
    request: Promise<T>,
    timeout: number,
): Promise<T> => {
    const timeoutRef: {
        current: NodeJS.Timeout;
    } = { current: null };
    const rejectOnTimeout = new Promise<null>((_, reject) => {
        timeoutRef.current = setTimeout(
            () => reject(Error(CustomErrors.WAIT_TIME_EXCEEDED)),
            timeout,
        );
    });
    const requestWithTimeOutCancellation = async () => {
        const resp = await request;
        clearTimeout(timeoutRef.current);
        return resp;
    };
    return await Promise.race([
        requestWithTimeOutCancellation(),
        rejectOnTimeout,
    ]);
};
