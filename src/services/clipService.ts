import * as log from 'electron-log';
import util from 'util';
import { logErrorSentry } from './sentry';
import { isDev } from '../utils/common';
import { app } from 'electron';
import path from 'path';
import { existsSync } from 'fs';
import fs from 'fs/promises';
const shellescape = require('any-shell-escape');
const execAsync = util.promisify(require('child_process').exec);
import fetch from 'node-fetch';
import { writeNodeStream } from './fs';
import { getPlatform } from '../utils/common/platform';

const CLIP_MODEL_PATH_PLACEHOLDER = 'CLIP_MODEL';
const GGMLCLIP_PATH_PLACEHOLDER = 'GGML_PATH';
const INPUT_PATH_PLACEHOLDER = 'INPUT';

const IMAGE_EMBEDDING_EXTRACT_CMD: string[] = [
    GGMLCLIP_PATH_PLACEHOLDER,
    '-mv',
    CLIP_MODEL_PATH_PLACEHOLDER,
    '--image',
    INPUT_PATH_PLACEHOLDER,
];

const TEXT_EMBEDDING_EXTRACT_CMD: string[] = [
    GGMLCLIP_PATH_PLACEHOLDER,
    '-mt',
    CLIP_MODEL_PATH_PLACEHOLDER,
    '--text',
    INPUT_PATH_PLACEHOLDER,
];

const TEXT_MODEL_DOWNLOAD_URL =
    'https://models.ente.io/clip-vit-base-patch32_ggml-text-model-f16.gguf';
const IMAGE_MODEL_DOWNLOAD_URL =
    'https://models.ente.io/clip-vit-base-patch32_ggml-vision-model-f16.gguf';

const TEXT_MODEL_NAME = 'clip-vit-base-patch32_ggml-text-model-f16.gguf';
const IMAGE_MODEL_NAME = 'clip-vit-base-patch32_ggml-vision-model-f16.gguf';

const IMAGE_MODEL_SIZE_IN_BYTES = 175957504; // 167.8 MB
const TEXT_MODEL_SIZE_IN_BYTES = 127853440; // 121.9 MB
const MODEL_SAVE_FOLDER = 'models';

function getModelSavePath(modelName: string) {
    let userDataDir: string;
    if (isDev) {
        userDataDir = '.';
    } else {
        userDataDir = app.getPath('userData');
    }
    return path.join(userDataDir, MODEL_SAVE_FOLDER, modelName);
}

async function downloadModel(saveLocation: string, url: string) {
    // confirm that the save location exists
    const saveDir = path.dirname(saveLocation);
    if (!existsSync(saveDir)) {
        log.info('creating model save dir');
        await fs.mkdir(saveDir, { recursive: true });
    }
    log.info('downloading clip model');
    const resp = await fetch(url);
    await writeNodeStream(saveLocation, resp.body, true);
    log.info('clip model downloaded');
}

let imageModelDownloadInProgress: Promise<void> = null;

export async function getClipImageModelPath() {
    const modelSavePath = getModelSavePath(IMAGE_MODEL_NAME);
    if (imageModelDownloadInProgress) {
        log.info('waiting for image model download to finish');
        await imageModelDownloadInProgress;
    } else {
        if (!existsSync(modelSavePath)) {
            log.info('clip image model not found, downloading');
            imageModelDownloadInProgress = downloadModel(
                modelSavePath,
                IMAGE_MODEL_DOWNLOAD_URL
            );
            await imageModelDownloadInProgress;
        } else {
            const localFileSize = (await fs.stat(modelSavePath)).size;
            if (localFileSize !== IMAGE_MODEL_SIZE_IN_BYTES) {
                log.info('clip model size mismatch, downloading again');
                imageModelDownloadInProgress = downloadModel(
                    modelSavePath,
                    IMAGE_MODEL_DOWNLOAD_URL
                );
                await imageModelDownloadInProgress;
            }
        }
    }
    return modelSavePath;
}

let textModelDownloadInProgress: Promise<void> = null;

export async function getClipTextModelPath() {
    const modelSavePath = getModelSavePath(TEXT_MODEL_NAME);
    if (textModelDownloadInProgress) {
        log.info('waiting for text model download to finish');
        await textModelDownloadInProgress;
    } else {
        if (!existsSync(modelSavePath)) {
            log.info('clip text model not found, downloading');
            textModelDownloadInProgress = downloadModel(
                modelSavePath,
                TEXT_MODEL_DOWNLOAD_URL
            );
            await textModelDownloadInProgress;
        } else {
            const localFileSize = (await fs.stat(modelSavePath)).size;
            if (localFileSize !== TEXT_MODEL_SIZE_IN_BYTES) {
                log.info('clip model size mismatch, downloading again');
                textModelDownloadInProgress = downloadModel(
                    modelSavePath,
                    TEXT_MODEL_DOWNLOAD_URL
                );
                await textModelDownloadInProgress;
            }
        }
    }
    return modelSavePath;
}

function getGGMLClipPath() {
    return isDev
        ? path.join('./build', `ggmlclip-${getPlatform()}`)
        : path.join(process.resourcesPath, `ggmlclip-${getPlatform()}`);
}

export async function computeImageEmbedding(
    inputFilePath: string
): Promise<Float32Array> {
    try {
        const clipModelPath = await getClipImageModelPath();
        const ggmlclipPath = getGGMLClipPath();
        const cmd = IMAGE_EMBEDDING_EXTRACT_CMD.map((cmdPart) => {
            if (cmdPart === GGMLCLIP_PATH_PLACEHOLDER) {
                return ggmlclipPath;
            } else if (cmdPart === CLIP_MODEL_PATH_PLACEHOLDER) {
                return clipModelPath;
            } else if (cmdPart === INPUT_PATH_PLACEHOLDER) {
                return inputFilePath;
            } else {
                return cmdPart;
            }
        });

        const escapedCmd = shellescape(cmd);
        log.info('running clip command', escapedCmd);
        const startTime = Date.now();
        const { stdout, stderr } = await execAsync(escapedCmd);
        log.info('clip command execution time ', Date.now() - startTime);
        // parse stdout and return embedding
        // get the last line of stdout
        log.info('stdout', stdout);
        log.info('stderr', stderr);
        const lines = stdout.split('\n');
        const lastLine = lines[lines.length - 1];
        const embedding = JSON.parse(lastLine);
        const embeddingArray = new Float32Array(embedding);
        return embeddingArray;
    } catch (err) {
        logErrorSentry(err, 'Error in computeImageEmbedding');
    }
}

export async function computeTextEmbedding(
    text: string
): Promise<Float32Array> {
    try {
        const clipModelPath = await getClipTextModelPath();
        const ggmlclipPath = getGGMLClipPath();
        const cmd = TEXT_EMBEDDING_EXTRACT_CMD.map((cmdPart) => {
            if (cmdPart === GGMLCLIP_PATH_PLACEHOLDER) {
                return ggmlclipPath;
            } else if (cmdPart === CLIP_MODEL_PATH_PLACEHOLDER) {
                return clipModelPath;
            } else if (cmdPart === INPUT_PATH_PLACEHOLDER) {
                return text;
            } else {
                return cmdPart;
            }
        });

        const escapedCmd = shellescape(cmd);
        log.info('running clip command', escapedCmd);
        const startTime = Date.now();
        const { stdout } = await execAsync(escapedCmd);
        log.info('clip command execution time ', Date.now() - startTime);
        // parse stdout and return embedding
        // get the last line of stdout
        const lines = stdout.split('\n');
        const lastLine = lines[lines.length - 1];
        const embedding = JSON.parse(lastLine);
        const embeddingArray = new Float32Array(embedding);
        return embeddingArray;
    } catch (err) {
        logErrorSentry(err, 'Error in computeTextEmbedding');
    }
}
