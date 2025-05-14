/**
 * @file A bridge to the ffmpeg utility process. This code runs in the main
 * process.
 */

import { wrap } from "comlink";
import fs from "node:fs/promises";
import type { FFmpegCommand, ZipItem } from "../../types/ipc";
import {
    deleteTempFileIgnoringErrors,
    makeFileForStreamOrPathOrZipItem,
    makeTempFilePath,
} from "../utils/temp";
import type { FFmpegUtilityProcess } from "./ffmpeg-worker";
import { ffmpegUtilityProcessEndpoint } from "./workers";

/**
 * Return a handle to the ffmpeg utility process, starting it if needed.
 */
export const ffmpegUtilityProcess = () =>
    ffmpegUtilityProcessEndpoint().then((port) =>
        wrap<FFmpegUtilityProcess>(port),
    );

/**
 * Implement the IPC "ffmpegExec" contract, writing the input and output to
 * temporary files as needed, and then forward to the {@link ffmpegExec} running
 * in the utility process.
 */
export const ffmpegExec = async (
    command: FFmpegCommand,
    pathOrZipItem: string | ZipItem,
    outputFileExtension: string,
): Promise<Uint8Array> => {
    const worker = await ffmpegUtilityProcess();

    const {
        path: inputFilePath,
        isFileTemporary: isInputFileTemporary,
        writeToTemporaryFile: writeToTemporaryInputFile,
    } = await makeFileForStreamOrPathOrZipItem(pathOrZipItem);

    const outputFilePath = await makeTempFilePath(outputFileExtension);
    try {
        await writeToTemporaryInputFile();

        await worker.ffmpegExec(command, inputFilePath, outputFilePath);

        return await fs.readFile(outputFilePath);
    } finally {
        if (isInputFileTemporary)
            await deleteTempFileIgnoringErrors(inputFilePath);
        await deleteTempFileIgnoringErrors(outputFilePath);
    }
};
