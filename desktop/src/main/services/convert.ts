/** @file Image conversions */

import { existsSync } from "fs";
import fs from "node:fs/promises";
import path from "path";
import { CustomErrorMessage, ElectronFile } from "../../types/ipc";
import log from "../log";
import { writeStream } from "../stream";
import { execAsync, isDev } from "../utils-electron";
import { deleteTempFile, makeTempFilePath } from "../utils-temp";

export const convertToJPEG = async (
    fileName: string,
    imageData: Uint8Array,
): Promise<Uint8Array> => {
    const inputFilePath = await makeTempFilePath(fileName);
    const outputFilePath = await makeTempFilePath(".jpeg");

    // Construct the command first, it may throw on NotAvailable on win32.
    const command = convertToJPEGCommand(inputFilePath, outputFilePath);

    try {
        await fs.writeFile(inputFilePath, imageData);
        await execAsync(command);
        return new Uint8Array(await fs.readFile(outputFilePath));
    } finally {
        try {
            deleteTempFile(outputFilePath);
            deleteTempFile(inputFilePath);
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

const IMAGE_MAGICK_PLACEHOLDER = "IMAGE_MAGICK";
const MAX_DIMENSION_PLACEHOLDER = "MAX_DIMENSION";
const SAMPLE_SIZE_PLACEHOLDER = "SAMPLE_SIZE";
const INPUT_PATH_PLACEHOLDER = "INPUT";
const OUTPUT_PATH_PLACEHOLDER = "OUTPUT";
const QUALITY_PLACEHOLDER = "QUALITY";

const MAX_QUALITY = 70;
const MIN_QUALITY = 50;

const SIPS_THUMBNAIL_GENERATE_COMMAND_TEMPLATE = [
    "sips",
    "-s",
    "format",
    "jpeg",
    "-s",
    "formatOptions",
    QUALITY_PLACEHOLDER,
    "-Z",
    MAX_DIMENSION_PLACEHOLDER,
    INPUT_PATH_PLACEHOLDER,
    "--out",
    OUTPUT_PATH_PLACEHOLDER,
];

const IMAGE_MAGICK_THUMBNAIL_GENERATE_COMMAND_TEMPLATE = [
    IMAGE_MAGICK_PLACEHOLDER,
    INPUT_PATH_PLACEHOLDER,
    "-auto-orient",
    "-define",
    `jpeg:size=${SAMPLE_SIZE_PLACEHOLDER}x${SAMPLE_SIZE_PLACEHOLDER}`,
    "-thumbnail",
    `${MAX_DIMENSION_PLACEHOLDER}x${MAX_DIMENSION_PLACEHOLDER}>`,
    "-unsharp",
    "0x.5",
    "-quality",
    QUALITY_PLACEHOLDER,
    OUTPUT_PATH_PLACEHOLDER,
];

export async function generateImageThumbnail(
    inputFile: File | ElectronFile,
    maxDimension: number,
    maxSize: number,
): Promise<Uint8Array> {
    let inputFilePath = null;
    let createdTempInputFile = null;
    try {
        if (process.platform == "win32")
            throw Error(
                CustomErrors.WINDOWS_NATIVE_IMAGE_PROCESSING_NOT_SUPPORTED,
            );
        if (!existsSync(inputFile.path)) {
            const tempFilePath = await makeTempFilePath(inputFile.name);
            await writeStream(tempFilePath, await inputFile.stream());
            inputFilePath = tempFilePath;
            createdTempInputFile = true;
        } else {
            inputFilePath = inputFile.path;
        }
        const thumbnail = await generateImageThumbnail_(
            inputFilePath,
            maxDimension,
            maxSize,
        );
        return thumbnail;
    } finally {
        if (createdTempInputFile) {
            try {
                await deleteTempFile(inputFilePath);
            } catch (e) {
                log.error(`Failed to deleteTempFile ${inputFilePath}`, e);
            }
        }
    }
}

async function generateImageThumbnail_(
    inputFilePath: string,
    width: number,
    maxSize: number,
): Promise<Uint8Array> {
    let tempOutputFilePath: string;
    let quality = MAX_QUALITY;
    try {
        tempOutputFilePath = await makeTempFilePath(".jpeg");
        let thumbnail: Uint8Array;
        do {
            await execAsync(
                constructThumbnailGenerationCommand(
                    inputFilePath,
                    tempOutputFilePath,
                    width,
                    quality,
                ),
            );
            thumbnail = new Uint8Array(await fs.readFile(tempOutputFilePath));
            quality -= 10;
        } while (thumbnail.length > maxSize && quality > MIN_QUALITY);
        return thumbnail;
    } catch (e) {
        log.error("Failed to generate image thumbnail", e);
        throw e;
    } finally {
        try {
            await fs.rm(tempOutputFilePath, { force: true });
        } catch (e) {
            log.error(
                `Failed to remove tempOutputFile ${tempOutputFilePath}`,
                e,
            );
        }
    }
}

function constructThumbnailGenerationCommand(
    inputFilePath: string,
    tempOutputFilePath: string,
    maxDimension: number,
    quality: number,
) {
    let thumbnailGenerationCmd: string[];
    if (process.platform == "darwin") {
        thumbnailGenerationCmd = SIPS_THUMBNAIL_GENERATE_COMMAND_TEMPLATE.map(
            (cmdPart) => {
                if (cmdPart === INPUT_PATH_PLACEHOLDER) {
                    return inputFilePath;
                }
                if (cmdPart === OUTPUT_PATH_PLACEHOLDER) {
                    return tempOutputFilePath;
                }
                if (cmdPart === MAX_DIMENSION_PLACEHOLDER) {
                    return maxDimension.toString();
                }
                if (cmdPart === QUALITY_PLACEHOLDER) {
                    return quality.toString();
                }
                return cmdPart;
            },
        );
    } else if (process.platform == "linux") {
        thumbnailGenerationCmd =
            IMAGE_MAGICK_THUMBNAIL_GENERATE_COMMAND_TEMPLATE.map((cmdPart) => {
                if (cmdPart === IMAGE_MAGICK_PLACEHOLDER) {
                    return imageMagickPath();
                }
                if (cmdPart === INPUT_PATH_PLACEHOLDER) {
                    return inputFilePath;
                }
                if (cmdPart === OUTPUT_PATH_PLACEHOLDER) {
                    return tempOutputFilePath;
                }
                if (cmdPart.includes(SAMPLE_SIZE_PLACEHOLDER)) {
                    return cmdPart.replaceAll(
                        SAMPLE_SIZE_PLACEHOLDER,
                        (2 * maxDimension).toString(),
                    );
                }
                if (cmdPart.includes(MAX_DIMENSION_PLACEHOLDER)) {
                    return cmdPart.replaceAll(
                        MAX_DIMENSION_PLACEHOLDER,
                        maxDimension.toString(),
                    );
                }
                if (cmdPart === QUALITY_PLACEHOLDER) {
                    return quality.toString();
                }
                return cmdPart;
            });
    } else {
        throw new Error(`Unsupported OS ${process.platform}`);
    }
    return thumbnailGenerationCmd;
}
