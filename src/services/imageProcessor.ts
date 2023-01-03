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
const shellescape = require('any-shell-escape');

const asyncExec = util.promisify(exec);

const IMAGE_MAGICK_PLACEHOLDER = 'IMAGE_MAGICK';
const MAX_DIMENSION_PLACEHOLDER = 'MAX_DIMENSION';
const SAMPLE_SIZE_PLACEHOLDER = 'SAMPLE_SIZE';
const INPUT_PATH_PLACEHOLDER = 'INPUT';
const OUTPUT_PATH_PLACEHOLDER = 'OUTPUT';

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
    INPUT_PATH_PLACEHOLDER,
    '-Z',
    MAX_DIMENSION_PLACEHOLDER,
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
        Error(`${process.platform} native heic convert not supported yet`);
    }
    return convertCmd;
}

export async function generateImageThumbnail(
    inputFilePath: string,
    width: number
): Promise<Uint8Array> {
    let tempOutputFilePath: string;
    try {
        tempOutputFilePath = await generateTempFilePath('thumb.jpeg');

        await runThumbnailGenerationCommand(
            inputFilePath,
            tempOutputFilePath,
            width
        );

        if (!existsSync(tempOutputFilePath)) {
            throw new Error('output thumbnail file not found');
        }
        const thumbnail = new Uint8Array(await readFile(tempOutputFilePath));
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
    maxDimension: number
) {
    const thumbnailGenerationCmd: string[] =
        constructThumbnailGenerationCommand(
            inputFilePath,
            tempOutputFilePath,
            maxDimension
        );
    const escapedCmd = shellescape(thumbnailGenerationCmd);
    log.info('running thumbnail generation command: ' + escapedCmd);
    await asyncExec(escapedCmd);
}
function constructThumbnailGenerationCommand(
    inputFilePath: string,
    tempOutputFilePath: string,
    maxDimension: number
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
                if (cmdPart === SAMPLE_SIZE_PLACEHOLDER) {
                    return (2 * maxDimension).toString();
                }
                if (cmdPart === MAX_DIMENSION_PLACEHOLDER) {
                    return maxDimension.toString();
                }
                return cmdPart;
            });
    } else {
        Error(
            `${process.platform} native thumbnail generation not supported yet`
        );
    }
    return thumbnailGenerationCmd;
}
