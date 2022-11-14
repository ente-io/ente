import { ipcRenderer } from 'electron';
import { ElectronFile } from '../types';

export function runFFmpegCmd(
    cmd: string[],
    inputFile: ElectronFile,
    outputFileName: string
) {
    return ipcRenderer.invoke('run-ffmpeg-cmd', cmd, inputFile, outputFileName);
}
