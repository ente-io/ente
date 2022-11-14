import pathToFfmpeg from 'ffmpeg-static';
import path from 'path';
import { ElectronFile } from '../types';
const shellescape = require('any-shell-escape');
import util from 'util';
const exec = util.promisify(require('child_process').exec);
import { getElectronFile } from './fs';
import log from 'electron-log';
import { rmSync } from 'promise-fs';
import { logErrorSentry } from './sentry';
import { generateTempName, getTempDirPath } from '../utils/temp';

function getFFmpegStaticPath() {
    return pathToFfmpeg.replace('app.asar', 'app.asar.unpacked');
}

export async function generateVideoThumbnail(
    cmd: string[],
    inputFile: ElectronFile
) {
    let tempOutputFilePath;
    try {
        const tempDirPath = await getTempDirPath();
        const tempName = generateTempName(10);
        tempOutputFilePath = path.join(tempDirPath, tempName + '.jpeg');

        for (let i = 0; i < cmd.length; i++) {
            if (cmd[i] === 'FFMPEG') {
                cmd[i] = getFFmpegStaticPath();
            } else if (cmd[i] === 'INPUT') {
                cmd[i] = inputFile.path;
            } else if (cmd[i] === 'OUTPUT') {
                cmd[i] = tempOutputFilePath;
            }
        }

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

// async getTranscodedFile(
//     cmds: string[],
//     inputFile: ElectronFile,
//     outputFileExt: string
// ): Promise<ElectronFile> {
//     try {
//         const tempDirPath = await getTempDirPath();
//         const outputFileName = generateTempName(10) + '.' + outputFileExt;
//         const outputFilePath = path.join(tempDirPath, outputFileName);
//         for (let i = 0; i < cmds.length; i++) {
//             if (cmds[i] === 'FFMPEG') {
//                 cmds[i] = this.ffmpegPath;
//             } else if (cmds[i] === 'INPUT') {
//                 cmds[i] = inputFile.path
//                     .split(path.posix.sep)
//                     .join(path.sep);
//             } else if (cmds[i] === 'OUTPUT') {
//                 cmds[i] = outputFilePath;
//             }
//         }
//         const cmd = shellescape(cmds);
//         console.log('cmd', cmd);
//         await exec(cmd);
//         const outputFile = await getElectronFile(outputFilePath);
//         return outputFile;
//     } catch (err) {
//         console.log(err);
//         logError(err, 'ffmpeg run command error');
//     }
// }
