import { app } from 'electron';
import path from 'path';
import { existsSync, mkdir } from 'promise-fs';

const ENTE_TEMP_DIRECTORY = 'ente';

const CHARACTERS =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

export async function getTempDirPath() {
    const tempDirPath = path.join(app.getPath('temp'), ENTE_TEMP_DIRECTORY);
    if (!existsSync(tempDirPath)) {
        await mkdir(tempDirPath);
    }
    return tempDirPath;
}

function generateTempName(length: number) {
    let result = '';

    const charactersLength = CHARACTERS.length;
    for (let i = 0; i < length; i++) {
        result += CHARACTERS.charAt(
            Math.floor(Math.random() * charactersLength)
        );
    }
    return result;
}

export async function generateTempFilePath(formatSuffix: string) {
    const tempDirPath = await getTempDirPath();
    const namePrefix = generateTempName(10);
    const tempFilePath = path.join(
        tempDirPath,
        namePrefix + '-' + formatSuffix
    );
    return tempFilePath;
}
