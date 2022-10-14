import { exec } from 'child_process';
import { app } from 'electron';
import path from 'path';
import { readFile, writeFile } from 'promise-fs';
import { nanoid } from 'nanoid';

export async function convertHEIC(
    heicFileData: Uint8Array
): Promise<Uint8Array> {
    const tempInputFileName = nanoid() + '.heic';
    const tempInputOutputName = nanoid() + '.jpeg';
    const tempDir = app.getPath('temp');
    writeFile(path.join(tempDir, tempInputFileName), heicFileData);
    exec(
        `sips -s format jpeg ${tempInputFileName} --out ${tempInputOutputName}`
    );
    const convertedFileData = new Uint8Array(
        await readFile(tempInputOutputName)
    );
    return convertedFileData;
}
