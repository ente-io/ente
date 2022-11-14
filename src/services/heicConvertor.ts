import { exec, ExecException } from 'child_process';
import { rmSync } from 'fs';
import path from 'path';
import { readFile, writeFile } from 'promise-fs';
import { generateTempName, getTempDirPath } from '../utils/temp';
import { logErrorSentry } from './sentry';

export async function convertHEIC(
    heicFileData: Uint8Array
): Promise<Uint8Array> {
    let tempInputFilePath: string;
    let tempOutputFilePath: string;
    try {
        const tempDirPath = await getTempDirPath();
        const tempName = generateTempName(10);

        tempInputFilePath = path.join(tempDirPath, tempName + '.heic');
        tempOutputFilePath = path.join(tempDirPath, tempName + '.jpeg');

        await writeFile(tempInputFilePath, heicFileData);

        await new Promise((resolve, reject) => {
            exec(
                `sips -s format jpeg ${tempInputFilePath} --out ${tempOutputFilePath}`,
                (
                    error: ExecException | null,
                    stdout: string,
                    stderr: string
                ) => {
                    if (error) {
                        reject(error);
                    } else if (stderr) {
                        reject(stderr);
                    } else {
                        resolve(stdout);
                    }
                }
            );
        });
        const convertedFileData = new Uint8Array(
            await readFile(tempOutputFilePath)
        );
        return convertedFileData;
    } catch (e) {
        logErrorSentry(e, 'failed to convert heic');
        throw e;
    } finally {
        try {
            rmSync(tempInputFilePath);
        } catch (e) {
            logErrorSentry(e, 'failed to remove tempInputFile');
        }
        try {
            rmSync(tempOutputFilePath);
        } catch (e) {
            logErrorSentry(e, 'failed to remove tempOutputFile');
        }
    }
}
