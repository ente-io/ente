import pathToFfmpeg from 'ffmpeg-static';
import path from 'path';
const shellescape = require('any-shell-escape');
import util from 'util';
import log from 'electron-log';
import { readFile, rmSync, writeFile } from 'promise-fs';
import { logErrorSentry } from './sentry';
import { generateTempName, getTempDirPath } from '../utils/temp';

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
    inputFileData: Uint8Array,
    inputFileName: string,
    outputFileName: string
) {
    let outputFilePath: string;
    try {
        const tempDirPath = await getTempDirPath();
        const tempName = generateTempName(10);
        if (!inputFilePath) {
            inputFilePath = path.join(
                tempDirPath,
                tempName + '-' + inputFileName
            );
            await writeFile(inputFilePath, inputFileData);
        }
        outputFilePath = path.join(
            tempDirPath,
            tempName + '-' + outputFileName
        );

        cmd = cmd.map((cmdPart) => {
            if (cmdPart === FFMPEG_PLACEHOLDER) {
                return getFFmpegStaticPath();
            } else if (cmdPart === INPUT_PATH_PLACEHOLDER) {
                return inputFilePath;
            } else if (cmdPart === OUTPUT_PATH_PLACEHOLDER) {
                return outputFilePath;
            } else {
                return cmdPart;
            }
        });
        cmd = shellescape(cmd);
        log.info('cmd', cmd);
        await execAsync(cmd);
        return new Uint8Array(await readFile(outputFilePath));
    } catch (e) {
        logErrorSentry(e, 'ffmpeg run command error');
        throw e;
    } finally {
        try {
            rmSync(outputFilePath);
        } catch (e) {
            logErrorSentry(e, 'failed to remove tempOutputFile');
        }
    }
}
