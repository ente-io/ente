import util from 'util';
import { exec } from 'child_process';

import { existsSync, rmSync } from 'fs';
import { readFile, writeFile } from 'promise-fs';
import { generateTempFilePath } from '../utils/temp';
import { logErrorSentry } from './sentry';
import { isPlatform } from '../utils/main';
import { isDev } from '../utils/common';
import path from 'path';
import log from 'electron-log';
import { CustomErrors } from '../constants/errors';
const shellescape = require('any-shell-escape');

const asyncExec = util.promisify(exec);

const IMAGE_MAGICK_PLACEHOLDER = 'IMAGE_MAGICK';
const MAX_DIMENSION_PLACEHOLDER = 'MAX_DIMENSION';
const SAMPLE_SIZE_PLACEHOLDER = 'SAMPLE_SIZE';
const INPUT_PATH_PLACEHOLDER = 'INPUT';
const OUTPUT_PATH_PLACEHOLDER = 'OUTPUT';
const QUALITY_PLACEHOLDER = 'QUALITY';

const MAX_QUALITY = 70;
const MIN_QUALITY = 50;

const SIPS_HEIC_CONVERT_COMMAND_TEMPLATE = [
    'sips',
    '-s',
    'format',
    'jpeg',
    INPUT_PATH_PLACEHOLDER,
    '--out',
    OUTPUT_PATH_PLACEHOLDER,
];

const SIPS_THUMBNAIL_GENERATE_COMMAND_TEMPLATE = [
    'sips',
    '-s',
    'format',
    'jpeg',
    '-s',
    'formatOptions',
    QUALITY_PLACEHOLDER,
    '-Z',
    MAX_DIMENSION_PLACEHOLDER,
    INPUT_PATH_PLACEHOLDER,
    '--out',
    OUTPUT_PATH_PLACEHOLDER,
];

const IMAGEMAGICK_HEIC_CONVERT_COMMAND_TEMPLATE = [
    IMAGE_MAGICK_PLACEHOLDER,
    INPUT_PATH_PLACEHOLDER,
    '-quality',
    '100%',
    OUTPUT_PATH_PLACEHOLDER,
];

const IMAGE_MAGICK_THUMBNAIL_GENERATE_COMMAND_TEMPLATE = [
    IMAGE_MAGICK_PLACEHOLDER,
    '-define',
    `jpeg:size=${SAMPLE_SIZE_PLACEHOLDER}x${SAMPLE_SIZE_PLACEHOLDER}`,
    INPUT_PATH_PLACEHOLDER,
    '-thumbnail',
    `${MAX_DIMENSION_PLACEHOLDER}x${MAX_DIMENSION_PLACEHOLDER}>`,
    '-unsharp',
    '0x.5',
    '-quality',
    QUALITY_PLACEHOLDER,
    OUTPUT_PATH_PLACEHOLDER,
];

function getImageMagickStaticPath() {
    return isDev
        ? 'build/image-magick'
        : path.join(process.resourcesPath, 'image-magick');
}

export async function convertHEIC(
    heicFileData: Uint8Array
): Promise<Uint8Array> {
    let tempInputFilePath: string;
    let tempOutputFilePath: string;
    if (isPlatform('windows')) {
        throw Error(CustomErrors.WINDOWS_NATIVE_IMAGE_PROCESSING_NOT_SUPPORTED);
    }
    try {
        tempInputFilePath = await generateTempFilePath('input.heic');
        tempOutputFilePath = await generateTempFilePath('output.jpeg');

        await writeFile(tempInputFilePath, heicFileData);

        await runConvertCommand(tempInputFilePath, tempOutputFilePath);

        if (!existsSync(tempOutputFilePath)) {
            throw new Error('heic convert output file not found');
        }
        const convertedFileData = new Uint8Array(
            await readFile(tempOutputFilePath)
        );
        return convertedFileData;
    } catch (e) {
        logErrorSentry(e, 'failed to convert heic');
        throw e;
    } finally {
        try {
            rmSync(tempInputFilePath, { force: true });
        } catch (e) {
            logErrorSentry(e, 'failed to remove tempInputFile');
        }
        try {
            rmSync(tempOutputFilePath, { force: true });
        } catch (e) {
            logErrorSentry(e, 'failed to remove tempOutputFile');
        }
    }
}

async function runConvertCommand(
    tempInputFilePath: string,
    tempOutputFilePath: string
) {
    const convertCmd = constructConvertCommand(
        tempInputFilePath,
        tempOutputFilePath
    );
    const escapedCmd = shellescape(convertCmd);
    log.info('running convert command: ' + escapedCmd);
    await asyncExec(escapedCmd);
}

function constructConvertCommand(
    tempInputFilePath: string,
    tempOutputFilePath: string
) {
    let convertCmd: string[];
    if (isPlatform('mac')) {
        convertCmd = SIPS_HEIC_CONVERT_COMMAND_TEMPLATE.map((cmdPart) => {
            if (cmdPart === INPUT_PATH_PLACEHOLDER) {
                return tempInputFilePath;
            }
            if (cmdPart === OUTPUT_PATH_PLACEHOLDER) {
                return tempOutputFilePath;
            }
            return cmdPart;
        });
    } else if (isPlatform('linux')) {
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
            }
        );
    } else {
        throw Error(CustomErrors.INVALID_OS(process.platform));
    }
    return convertCmd;
}

export async function generateImageThumbnail(
    inputFilePath: string,
    width: number,
    maxSize: number
): Promise<Uint8Array> {
    let tempOutputFilePath: string;
    let quality = MAX_QUALITY;
    if (isPlatform('windows')) {
        throw Error(CustomErrors.WINDOWS_NATIVE_IMAGE_PROCESSING_NOT_SUPPORTED);
    }
    try {
        tempOutputFilePath = await generateTempFilePath('thumb.jpeg');
        let thumbnail: Uint8Array;
        do {
            await runThumbnailGenerationCommand(
                inputFilePath,
                tempOutputFilePath,
                width,
                quality
            );

            if (!existsSync(tempOutputFilePath)) {
                throw new Error('output thumbnail file not found');
            }
            thumbnail = new Uint8Array(await readFile(tempOutputFilePath));
            quality -= 10;
        } while (thumbnail.length > maxSize && quality > MIN_QUALITY);
        return thumbnail;
    } catch (e) {
        logErrorSentry(e, 'generate image thumbnail failed');
        throw e;
    } finally {
        try {
            rmSync(tempOutputFilePath, { force: true });
        } catch (e) {
            logErrorSentry(e, 'failed to remove tempOutputFile');
        }
    }
}

async function runThumbnailGenerationCommand(
    inputFilePath: string,
    tempOutputFilePath: string,
    maxDimension: number,
    quality: number
) {
    const thumbnailGenerationCmd: string[] =
        constructThumbnailGenerationCommand(
            inputFilePath,
            tempOutputFilePath,
            maxDimension,
            quality
        );
    const escapedCmd = shellescape(thumbnailGenerationCmd);
    log.info('running thumbnail generation command: ' + escapedCmd);
    await asyncExec(escapedCmd);
}
function constructThumbnailGenerationCommand(
    inputFilePath: string,
    tempOutputFilePath: string,
    maxDimension: number,
    quality: number
) {
    let thumbnailGenerationCmd: string[];
    if (isPlatform('mac')) {
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
            }
        );
    } else if (isPlatform('linux')) {
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
                        (2 * maxDimension).toString()
                    );
                }
                if (cmdPart.includes(MAX_DIMENSION_PLACEHOLDER)) {
                    return cmdPart.replaceAll(
                        MAX_DIMENSION_PLACEHOLDER,
                        maxDimension.toString()
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
