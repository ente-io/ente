import log from "electron-log";
import pathToFfmpeg from "ffmpeg-static";
import { existsSync } from "fs";
import { readFile, rmSync, writeFile } from "promise-fs";
import util from "util";
import { promiseWithTimeout } from "../utils/common";
import { generateTempFilePath, getTempDirPath } from "../utils/temp";
import { logErrorSentry } from "./sentry";
const shellescape = require("any-shell-escape");

const execAsync = util.promisify(require("child_process").exec);

const FFMPEG_EXECUTION_WAIT_TIME = 30 * 1000;

const INPUT_PATH_PLACEHOLDER = "INPUT";
const FFMPEG_PLACEHOLDER = "FFMPEG";
const OUTPUT_PATH_PLACEHOLDER = "OUTPUT";

function getFFmpegStaticPath() {
    return pathToFfmpeg.replace("app.asar", "app.asar.unpacked");
}

export async function runFFmpegCmd(
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
                return getFFmpegStaticPath();
            } else if (cmdPart === INPUT_PATH_PLACEHOLDER) {
                return inputFilePath;
            } else if (cmdPart === OUTPUT_PATH_PLACEHOLDER) {
                return tempOutputFilePath;
            } else {
                return cmdPart;
            }
        });
        const escapedCmd = shellescape(cmd);
        log.info("running ffmpeg command", escapedCmd);
        const startTime = Date.now();
        if (dontTimeout) {
            await execAsync(escapedCmd);
        } else {
            await promiseWithTimeout(
                execAsync(escapedCmd),
                FFMPEG_EXECUTION_WAIT_TIME,
            );
        }
        if (!existsSync(tempOutputFilePath)) {
            throw new Error("ffmpeg output file not found");
        }
        log.info(
            "ffmpeg command execution time ",
            escapedCmd,
            Date.now() - startTime,
            "ms",
        );

        const outputFile = await readFile(tempOutputFilePath);
        return new Uint8Array(outputFile);
    } catch (e) {
        logErrorSentry(e, "ffmpeg run command error");
        throw e;
    } finally {
        try {
            rmSync(tempOutputFilePath, { force: true });
        } catch (e) {
            logErrorSentry(e, "failed to remove tempOutputFile");
        }
    }
}

export async function writeTempFile(fileStream: Uint8Array, fileName: string) {
    const tempFilePath = await generateTempFilePath(fileName);
    await writeFile(tempFilePath, fileStream);
    return tempFilePath;
}

export async function deleteTempFile(tempFilePath: string) {
    const tempDirPath = await getTempDirPath();
    if (!tempFilePath.startsWith(tempDirPath)) {
        logErrorSentry(
            Error("not a temp file"),
            "tried to delete a non temp file",
        );
    }
    rmSync(tempFilePath, { force: true });
}
