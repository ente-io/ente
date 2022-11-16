import util from 'util';
import { exec } from 'child_process';

import { rmSync } from 'fs';
import { readFile, writeFile } from 'promise-fs';
import { generateTempFilePath } from '../utils/temp';
import { logErrorSentry } from './sentry';

const asyncExec = util.promisify(exec);

export async function convertHEIC(
    heicFileData: Uint8Array
): Promise<Uint8Array> {
    let tempInputFilePath: string;
    let tempOutputFilePath: string;
    try {
        tempInputFilePath = await generateTempFilePath('.heic');
        tempOutputFilePath = await generateTempFilePath('.jpeg');

        await writeFile(tempInputFilePath, heicFileData);

        await asyncExec(
            `sips -s format jpeg ${tempInputFilePath} --out ${tempOutputFilePath}`
        );
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
