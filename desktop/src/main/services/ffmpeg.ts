/**
 * @file A bridge to the ffmpeg utility process. This code runs in the main
 * process.
 */

import fs from "node:fs/promises";
import type { FFmpegCommand, ZipItem } from "../../types/ipc";
import {
    deleteTempFileIgnoringErrors,
    makeFileForDataOrStreamOrPathOrZipItem,
    makeTempFilePath,
} from "../utils/temp";
import type { FFmpegUtilityProcess } from "./ffmpeg-worker";
import { ffmpegUtilityProcessPort } from "./workers";

/**
 * Return a handle to the ffmpeg utility process, starting it if needed.
 */
export const ffmpegUtilityProcess = () => {
    return ffmpegUtilityProcessPort() as unknown as FFmpegUtilityProcess;
};

export const ffmpegExec = async (
    command: FFmpegCommand,
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

        await ffmpegUtilityProcess().ffmpegExec(
            command,
            inputFilePath,
            outputFilePath,
        );

        return await fs.readFile(outputFilePath);
    } finally {
        if (isInputFileTemporary)
            await deleteTempFileIgnoringErrors(inputFilePath);
        await deleteTempFileIgnoringErrors(outputFilePath);
    }
};
