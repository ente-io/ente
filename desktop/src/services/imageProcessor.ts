import { existsSync } from "fs";
import fs from "node:fs/promises";
import path from "path";
import { CustomErrors } from "../constants/errors";
import { writeStream } from "../main/fs";
import { logError, logErrorSentry } from "../main/log";
import { execAsync, isDev } from "../main/util";
import { ElectronFile } from "../types/ipc";
import { isPlatform } from "../utils/common/platform";
import { generateTempFilePath } from "../utils/temp";
import { deleteTempFile } from "./ffmpeg";

const IMAGE_MAGICK_PLACEHOLDER = "IMAGE_MAGICK";
const MAX_DIMENSION_PLACEHOLDER = "MAX_DIMENSION";
const SAMPLE_SIZE_PLACEHOLDER = "SAMPLE_SIZE";
const INPUT_PATH_PLACEHOLDER = "INPUT";
const OUTPUT_PATH_PLACEHOLDER = "OUTPUT";
const QUALITY_PLACEHOLDER = "QUALITY";

const MAX_QUALITY = 70;
const MIN_QUALITY = 50;

const SIPS_HEIC_CONVERT_COMMAND_TEMPLATE = [
    "sips",
    "-s",
    "format",
    "jpeg",
    INPUT_PATH_PLACEHOLDER,
    "--out",
    OUTPUT_PATH_PLACEHOLDER,
];

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

const IMAGEMAGICK_HEIC_CONVERT_COMMAND_TEMPLATE = [
    IMAGE_MAGICK_PLACEHOLDER,
    INPUT_PATH_PLACEHOLDER,
    "-quality",
    "100%",
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

function getImageMagickStaticPath() {
    return isDev
        ? "resources/image-magick"
        : path.join(process.resourcesPath, "image-magick");
}

export async function convertToJPEG(
    fileData: Uint8Array,
    filename: string,
): Promise<Uint8Array> {
    if (isPlatform("windows")) {
        throw Error(CustomErrors.WINDOWS_NATIVE_IMAGE_PROCESSING_NOT_SUPPORTED);
    }
    const convertedFileData = await convertToJPEG_(fileData, filename);
    return convertedFileData;
}

async function convertToJPEG_(
    fileData: Uint8Array,
    filename: string,
): Promise<Uint8Array> {
    let tempInputFilePath: string;
    let tempOutputFilePath: string;
    try {
        tempInputFilePath = await generateTempFilePath(filename);
        tempOutputFilePath = await generateTempFilePath("output.jpeg");

        await fs.writeFile(tempInputFilePath, fileData);

        await execAsync(
            constructConvertCommand(tempInputFilePath, tempOutputFilePath),
        );

        return new Uint8Array(await fs.readFile(tempOutputFilePath));
    } catch (e) {
        logErrorSentry(e, "failed to convert heic");
        throw e;
    } finally {
        try {
            await fs.rm(tempInputFilePath, { force: true });
        } catch (e) {
            logErrorSentry(e, "failed to remove tempInputFile");
        }
        try {
            await fs.rm(tempOutputFilePath, { force: true });
        } catch (e) {
            logErrorSentry(e, "failed to remove tempOutputFile");
        }
    }
}

function constructConvertCommand(
    tempInputFilePath: string,
    tempOutputFilePath: string,
) {
    let convertCmd: string[];
    if (isPlatform("mac")) {
        convertCmd = SIPS_HEIC_CONVERT_COMMAND_TEMPLATE.map((cmdPart) => {
            if (cmdPart === INPUT_PATH_PLACEHOLDER) {
                return tempInputFilePath;
            }
            if (cmdPart === OUTPUT_PATH_PLACEHOLDER) {
                return tempOutputFilePath;
            }
            return cmdPart;
        });
    } else if (isPlatform("linux")) {
        convertCmd = IMAGEMAGICK_HEIC_CONVERT_COMMAND_TEMPLATE.map(
            (cmdPart) => {
                if (cmdPart === IMAGE_MAGICK_PLACEHOLDER) {
                    return getImageMagickStaticPath();
                }
                if (cmdPart === INPUT_PATH_PLACEHOLDER) {
                    return tempInputFilePath;
                }
                if (cmdPart === OUTPUT_PATH_PLACEHOLDER) {
                    return tempOutputFilePath;
                }
                return cmdPart;
            },
        );
    } else {
        throw Error(CustomErrors.INVALID_OS(process.platform));
    }
    return convertCmd;
}

export async function generateImageThumbnail(
    inputFile: File | ElectronFile,
    maxDimension: number,
    maxSize: number,
): Promise<Uint8Array> {
    let inputFilePath = null;
    let createdTempInputFile = null;
    try {
        if (isPlatform("windows")) {
            throw Error(
                CustomErrors.WINDOWS_NATIVE_IMAGE_PROCESSING_NOT_SUPPORTED,
            );
        }
        if (!existsSync(inputFile.path)) {
            const tempFilePath = await generateTempFilePath(inputFile.name);
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
                logError(e, "failed to deleteTempFile");
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
        tempOutputFilePath = await generateTempFilePath("thumb.jpeg");
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
        logErrorSentry(e, "generate image thumbnail failed");
        throw e;
    } finally {
        try {
            await fs.rm(tempOutputFilePath, { force: true });
        } catch (e) {
            logErrorSentry(e, "failed to remove tempOutputFile");
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
    if (isPlatform("mac")) {
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
    } else if (isPlatform("linux")) {
        thumbnailGenerationCmd =
            IMAGE_MAGICK_THUMBNAIL_GENERATE_COMMAND_TEMPLATE.map((cmdPart) => {
                if (cmdPart === IMAGE_MAGICK_PLACEHOLDER) {
                    return getImageMagickStaticPath();
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
        throw Error(CustomErrors.INVALID_OS(process.platform));
    }
    return thumbnailGenerationCmd;
}
