import pathToFfmpeg from 'ffmpeg-static';
import path from 'path';
const shellescape = require('any-shell-escape');
import util from 'util';
const exec = util.promisify(require('child_process').exec);
import { getElectronFile } from './fs';
import log from 'electron-log';
import { rmSync } from 'promise-fs';
import { logErrorSentry } from './sentry';
import { generateTempName, getTempDirPath } from '../utils/temp';
import { ElectronFile } from '../types';

export const INPUT_PATH_PLACEHOLDER = 'INPUT';
export const FFMPEG_PLACEHOLDER = 'FFMPEG';
export const OUTPUT_PATH_PLACEHOLDER = 'OUTPUT';

function getFFmpegStaticPath() {
    return pathToFfmpeg.replace('app.asar', 'app.asar.unpacked');
}

export async function runFFmpegCmd(
    cmd: string[],
    inputFile: ElectronFile,
    outputFileName: string
) {
    let tempOutputFilePath: string;
    try {
        const tempDirPath = await getTempDirPath();
        const tempName = generateTempName(10);
        tempOutputFilePath = path.join(
            tempDirPath,
            tempName + '-' + outputFileName
        );

        cmd = cmd.map((cmdPart) => {
            if (cmdPart === FFMPEG_PLACEHOLDER) {
                return getFFmpegStaticPath();
            } else if (cmdPart === INPUT_PATH_PLACEHOLDER) {
                return inputFile.path;
            } else if (cmdPart === OUTPUT_PATH_PLACEHOLDER) {
                return tempOutputFilePath;
            } else {
                return cmdPart;
            }
        });
        cmd = shellescape(cmd);
        log.info('cmd', cmd);
        await exec(cmd);

        const outputFile = await getElectronFile(tempOutputFilePath);
        return outputFile;
    } catch (e) {
        logErrorSentry(e, 'ffmpeg run command error');
    } finally {
        try {
            rmSync(tempOutputFilePath);
        } catch (e) {
            logErrorSentry(e, 'failed to remove tempInputFile');
        }
    }
}
