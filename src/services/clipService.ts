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

const CLIP_MODEL_PATH_PLACEHOLDER = 'CLIP_MODEL';
const GGMLCLIP_PATH_PLACEHOLDER = 'GGML_PATH';
const INPUT_PATH_PLACEHOLDER = 'INPUT';
const MODEL_SIZE_IN_BYTES = 303606311; // 289.54 MB

const IMAGE_EMBEDDING_EXTRACT_CMD: string[] = [
    GGMLCLIP_PATH_PLACEHOLDER,
    '-m',
    CLIP_MODEL_PATH_PLACEHOLDER,
    '--image',
    INPUT_PATH_PLACEHOLDER,
];

const TEXT_EMBEDDING_EXTRACT_CMD: string[] = [
    GGMLCLIP_PATH_PLACEHOLDER,
    '-m',
    CLIP_MODEL_PATH_PLACEHOLDER,
    '--text',
    INPUT_PATH_PLACEHOLDER,
];

const GGML_CLIP_MODEL_DOWNLOAD_URL =
    'https://models.ente.io/openai_clip-vit-base-patch32.ggmlv0.f16.bin';
const MODEL_NAME = 'openai_clip-vit-base-patch32.ggmlv0.f16.bin';
const MODEL_SAVE_FOLDER = 'models';

function getModelSavePath() {
    let userDataDir: string;
    if (isDev) {
        userDataDir = '.';
    } else {
        userDataDir = app.getPath('userData');
    }
    return path.join(userDataDir, MODEL_SAVE_FOLDER, MODEL_NAME);
}

async function downloadModel(saveLocation: string) {
    // confirm that the save location exists
    const saveDir = path.dirname(saveLocation);
    if (!existsSync(saveDir)) {
        log.info('creating model save dir');
        await fs.mkdir(saveDir, { recursive: true });
    }
    log.info('downloading clip model');
    const resp = await fetch(GGML_CLIP_MODEL_DOWNLOAD_URL);
    await writeNodeStream(saveLocation, resp.body, true);
    log.info('clip model downloaded');
}

export async function getClipModelPath() {
    const modelSavePath = getModelSavePath();
    log.info('clip model save path', modelSavePath);
    if (!existsSync(modelSavePath)) {
        await downloadModel(modelSavePath);
    } else {
        const localFileSize = (await fs.stat(modelSavePath)).size;
        if (localFileSize !== MODEL_SIZE_IN_BYTES) {
            log.info('clip model size mismatch, downloading again');
            await downloadModel(modelSavePath);
        } else {
            log.info('clip model already downloaded');
        }
    }
    return modelSavePath;
}

function getGGMLClipPath() {
    return './bin/ggmlclip';
}

export async function computeImageEmbedding(
    inputFilePath: string
): Promise<Float32Array> {
    try {
        const clipModelPath = getClipModelPath();
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
        logErrorSentry(err, 'Error in computeImageEmbedding');
    }
}

export async function computeTextEmbedding(
    text: string
): Promise<Float32Array> {
    try {
        const clipModelPath = getClipModelPath();
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
        logErrorSentry(err, 'Error in computeImageEmbedding');
    }
}
