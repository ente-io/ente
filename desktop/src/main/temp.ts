import { app } from "electron/main";
import { existsSync } from "node:fs";
import fs from "node:fs/promises";
import path from "path";

const CHARACTERS =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";

export async function getTempDirPath() {
    const tempDirPath = path.join(app.getPath("temp"), "ente");
    await fs.mkdir(tempDirPath, { recursive: true });
    return tempDirPath;
}

function generateTempName(length: number) {
    let result = "";

    const charactersLength = CHARACTERS.length;
    for (let i = 0; i < length; i++) {
        result += CHARACTERS.charAt(
            Math.floor(Math.random() * charactersLength),
        );
    }
    return result;
}

export async function generateTempFilePath(formatSuffix: string) {
    let tempFilePath: string;
    do {
        const tempDirPath = await getTempDirPath();
        const namePrefix = generateTempName(10);
        tempFilePath = path.join(tempDirPath, namePrefix + "-" + formatSuffix);
    } while (existsSync(tempFilePath));
    return tempFilePath;
}
