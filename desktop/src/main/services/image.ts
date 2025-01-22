/** @file Image format conversions and thumbnail generation */

import fs from "node:fs/promises";
import path from "node:path";
import { type ZipItem } from "../../types/ipc";
import { execAsync, isDev } from "../utils/electron";
import {
    deleteTempFileIgnoringErrors,
    makeFileForDataOrPathOrZipItem,
    makeTempFilePath,
} from "../utils/temp";

export const convertToJPEG = async (imageData: Uint8Array) => {
    const inputFilePath = await makeTempFilePath();
    const outputFilePath = await makeTempFilePath("jpeg");

    // Construct the command first, it may throw NotAvailable on win32.
    const command = convertToJPEGCommand(inputFilePath, outputFilePath);

    try {
        await fs.writeFile(inputFilePath, imageData);
        await execAsync(command);
        return new Uint8Array(await fs.readFile(outputFilePath));
    } finally {
        await deleteTempFileIgnoringErrors(inputFilePath);
        await deleteTempFileIgnoringErrors(outputFilePath);
    }
};

const convertToJPEGCommand = (
    inputFilePath: string,
    outputFilePath: string,
) => {
    switch (process.platform) {
        case "darwin":
            return [
                "sips",
                "-s",
                "format",
                "jpeg",
                inputFilePath,
                "--out",
                outputFilePath,
            ];

        case "linux":
        case "win32":
            return [
                imageMagickPath(),
                "convert",
                inputFilePath,
                "-quality",
                "100%",
                outputFilePath,
            ];

        default:
            throw new Error("Not available on the current OS/arch");
    }
};

/**
 * Path to the magick executable bundled with our app on Linux and Windows.
 */
const imageMagickPath = () =>
    path.join(
        isDev ? "build" : process.resourcesPath,
        process.platform == "win32" ? "magick.exe" : "magick",
    );

export const generateImageThumbnail = async (
    dataOrPathOrZipItem: Uint8Array | string | ZipItem,
    maxDimension: number,
    maxSize: number,
): Promise<Uint8Array> => {
    const {
        path: inputFilePath,
        isFileTemporary: isInputFileTemporary,
        writeToTemporaryFile: writeToTemporaryInputFile,
    } = await makeFileForDataOrPathOrZipItem(dataOrPathOrZipItem);

    const outputFilePath = await makeTempFilePath("jpeg");

    // Construct the command first, it may throw `NotAvailable`.
    let quality = 70;
    let command = generateImageThumbnailCommand(
        inputFilePath,
        outputFilePath,
        maxDimension,
        quality,
    );

    try {
        await writeToTemporaryInputFile();

        let thumbnail: Uint8Array;
        do {
            await execAsync(command);
            thumbnail = new Uint8Array(await fs.readFile(outputFilePath));
            quality -= 10;
            command = generateImageThumbnailCommand(
                inputFilePath,
                outputFilePath,
                maxDimension,
                quality,
            );
        } while (thumbnail.length > maxSize && quality > 50);
        return thumbnail;
    } finally {
        if (isInputFileTemporary)
            await deleteTempFileIgnoringErrors(inputFilePath);
        await deleteTempFileIgnoringErrors(outputFilePath);
    }
};

const generateImageThumbnailCommand = (
    inputFilePath: string,
    outputFilePath: string,
    maxDimension: number,
    quality: number,
) => {
    switch (process.platform) {
        case "darwin":
            return [
                "sips",
                "-s",
                "format",
                "jpeg",
                "-s",
                "formatOptions",
                `${quality}`,
                "-Z",
                `${maxDimension}`,
                inputFilePath,
                "--out",
                outputFilePath,
            ];

        case "linux":
        case "win32":
            return [
                imageMagickPath(),
                "convert",
                inputFilePath,
                "-define",
                `jpeg:size=${2 * maxDimension}x${2 * maxDimension}`,
                "-auto-orient",
                "-thumbnail",
                `${maxDimension}x${maxDimension}`,
                "-unsharp",
                "0x.5",
                "-quality",
                `${quality}`,
                outputFilePath,
            ];

        default:
            throw new Error("Not available on the current OS/arch");
    }
};
