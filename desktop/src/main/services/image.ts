/** @file Image format conversions and thumbnail generation */

import fs from "node:fs/promises";
import path from "path";
import { CustomErrorMessage } from "../../types/ipc";
import log from "../log";
import { execAsync, isDev } from "../utils-electron";
import { deleteTempFile, makeTempFilePath } from "../utils-temp";

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
        try {
            await deleteTempFile(inputFilePath);
            await deleteTempFile(outputFilePath);
        } catch (e) {
            log.error("Ignoring error when cleaning up temp files", e);
        }
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
            return [
                imageMagickPath(),
                inputFilePath,
                "-quality",
                "100%",
                outputFilePath,
            ];

        default: // "win32"
            throw new Error(CustomErrorMessage.NotAvailable);
    }
};

/** Path to the Linux image-magick executable bundled with our app */
const imageMagickPath = () =>
    path.join(isDev ? "build" : process.resourcesPath, "image-magick");

export const generateImageThumbnail = async (
    dataOrPath: Uint8Array | string,
    maxDimension: number,
    maxSize: number,
): Promise<Uint8Array> => {
    let inputFilePath: string;
    let isInputFileTemporary: boolean;
    if (dataOrPath instanceof Uint8Array) {
        inputFilePath = await makeTempFilePath();
        isInputFileTemporary = true;
    } else {
        inputFilePath = dataOrPath;
        isInputFileTemporary = false;
    }

    const outputFilePath = await makeTempFilePath("jpeg");

    // Construct the command first, it may throw `NotAvailable` on win32.
    let quality = 70;
    let command = generateImageThumbnailCommand(
        inputFilePath,
        outputFilePath,
        maxDimension,
        quality,
    );

    try {
        if (dataOrPath instanceof Uint8Array)
            await fs.writeFile(inputFilePath, dataOrPath);

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
        try {
            if (isInputFileTemporary) await deleteTempFile(inputFilePath);
            await deleteTempFile(outputFilePath);
        } catch (e) {
            log.error("Ignoring error when cleaning up temp files", e);
        }
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
            return [
                imageMagickPath(),
                inputFilePath,
                "-auto-orient",
                "-define",
                `jpeg:size=${2 * maxDimension}x${2 * maxDimension}`,
                "-thumbnail",
                `${maxDimension}x${maxDimension}>`,
                "-unsharp",
                "0x.5",
                "-quality",
                `${quality}`,
                outputFilePath,
            ];

        default: // "win32"
            throw new Error(CustomErrorMessage.NotAvailable);
    }
};
