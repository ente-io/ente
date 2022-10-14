import { exec } from 'child_process';
import { app } from 'electron';
import path from 'path';
import { readFile, writeFile } from 'promise-fs';

export async function convertHEIC(
    heicFileData: Uint8Array
): Promise<Uint8Array> {
    const tempInputFileName = generateRandomName(10) + '.heic';
    const tempInputOutputName = generateRandomName(10) + '.jpeg';
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
