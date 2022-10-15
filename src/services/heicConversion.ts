import { exec, ExecException } from 'child_process';
import { app } from 'electron';
import { existsSync, rmSync } from 'fs';
import path from 'path';
import { mkdir, readFile, writeFile } from 'promise-fs';
import { logErrorSentry } from './sentry';

export async function convertHEIC(
    heicFileData: Uint8Array
): Promise<Uint8Array> {
    let tempInputFilePath: string;
    let tempOutputFilePath: string;
    try {
        const tempDir = path.join(app.getPath('temp'), 'ente');
        if (!existsSync(tempDir)) {
            await mkdir(tempDir);
        }
        tempInputFilePath = path.join(
            tempDir,
            generateRandomName(10) + '.heic'
        );
        tempOutputFilePath = path.join(
            tempDir,
            generateRandomName(10) + '.jpeg'
        );
        writeFile(tempInputFilePath, heicFileData);

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

function generateRandomName(length: number) {
    let result = '';
    const characters =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    const charactersLength = characters.length;
    for (let i = 0; i < length; i++) {
        result += characters.charAt(
            Math.floor(Math.random() * charactersLength)
        );
    }
    return result;
}
