import pathToFfmpeg from 'ffmpeg-static';
const shellescape = require('any-shell-escape');
import util from 'util';
import log from 'electron-log';
import { readFile, rmSync, writeFile } from 'promise-fs';
import { logErrorSentry } from './sentry';
import { generateTempFilePath, getTempDirPath } from '../utils/temp';

const execAsync = util.promisify(require('child_process').exec);

export const INPUT_PATH_PLACEHOLDER = 'INPUT';
export const FFMPEG_PLACEHOLDER = 'FFMPEG';
export const OUTPUT_PATH_PLACEHOLDER = 'OUTPUT';

function getFFmpegStaticPath() {
    return pathToFfmpeg.replace('app.asar', 'app.asar.unpacked');
}

export async function runFFmpegCmd(
    cmd: string[],
    inputFilePath: string,
    outputFileName: string
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
        cmd = shellescape(cmd);
        log.info('cmd', cmd);
        await execAsync(cmd);
        return new Uint8Array(await readFile(tempOutputFilePath));
    } catch (e) {
        logErrorSentry(e, 'ffmpeg run command error');
        throw e;
    } finally {
        try {
            rmSync(tempOutputFilePath);
        } catch (e) {
            logErrorSentry(e, 'failed to remove tempOutputFile');
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
            Error('not a temp file'),
            'tried to delete a non temp file'
        );
    }
    rmSync(tempFilePath);
}
