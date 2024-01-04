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
import { CustomErrors } from '../constants/errors';

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
const ort = require('onnxruntime-node');
const { encode } = require('gpt-3-encoder');
const { createCanvas, Image } = require('canvas');

const TEXT_MODEL_DOWNLOAD_URL = {
    ggml: 'https://models.ente.io/clip-vit-base-patch32_ggml-text-model-f16.gguf',
    onnx: 'https://huggingface.co/rocca/openai-clip-js/resolve/main/clip-text-vit-32-float32-int32.onnx',
};
const IMAGE_MODEL_DOWNLOAD_URL = {
    ggml: 'https://models.ente.io/clip-vit-base-patch32_ggml-vision-model-f16.gguf',
    onnx: 'https://huggingface.co/rocca/openai-clip-js/resolve/main/clip-image-vit-32-float32.onnx',
};

const TEXT_MODEL_NAME = {
    ggml: 'clip-vit-base-patch32_ggml-text-model-f16.gguf',
    onnx: 'clip-text-vit-32-float32-int32.onnx',
};
const IMAGE_MODEL_NAME = {
    ggml: 'clip-vit-base-patch32_ggml-vision-model-f16.gguf',
    onnx: 'clip-image-vit-32-float32.onnx',
};

const IMAGE_MODEL_SIZE_IN_BYTES = {
    ggml: 175957504, // 167.8 MB
    onnx: 351468764, // 335.2 MB
};
const TEXT_MODEL_SIZE_IN_BYTES = {
    ggml: 127853440, // 121.9 MB,
    onnx: 254069585, // 242.3 MB
};

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

export async function getClipImageModelPath(type: 'ggml' | 'onnx') {
    try {
        const modelSavePath = getModelSavePath(IMAGE_MODEL_NAME[type]);
        if (imageModelDownloadInProgress) {
            log.info('waiting for image model download to finish');
            await imageModelDownloadInProgress;
        } else {
            if (!existsSync(modelSavePath)) {
                log.info('clip image model not found, downloading');
                imageModelDownloadInProgress = downloadModel(
                    modelSavePath,
                    IMAGE_MODEL_DOWNLOAD_URL[type]
                );
                await imageModelDownloadInProgress;
            } else {
                const localFileSize = (await fs.stat(modelSavePath)).size;
                if (localFileSize !== IMAGE_MODEL_SIZE_IN_BYTES[type]) {
                    log.info(
                        'clip image model size mismatch, downloading again got:',
                        localFileSize
                    );
                    imageModelDownloadInProgress = downloadModel(
                        modelSavePath,
                        IMAGE_MODEL_DOWNLOAD_URL[type]
                    );
                    await imageModelDownloadInProgress;
                }
            }
        }
        return modelSavePath;
    } finally {
        imageModelDownloadInProgress = null;
    }
}

let textModelDownloadInProgress: boolean = false;

export async function getClipTextModelPath(type: 'ggml' | 'onnx') {
    const modelSavePath = getModelSavePath(TEXT_MODEL_NAME[type]);
    if (textModelDownloadInProgress) {
        throw Error(CustomErrors.MODEL_DOWNLOAD_PENDING);
    } else {
        if (!existsSync(modelSavePath)) {
            log.info('clip text model not found, downloading');
            textModelDownloadInProgress = true;
            downloadModel(modelSavePath, TEXT_MODEL_DOWNLOAD_URL[type])
                .catch(() => {
                    // ignore
                })
                .finally(() => {
                    textModelDownloadInProgress = false;
                });
            throw Error(CustomErrors.MODEL_DOWNLOAD_PENDING);
        } else {
            const localFileSize = (await fs.stat(modelSavePath)).size;
            if (localFileSize !== TEXT_MODEL_SIZE_IN_BYTES[type]) {
                log.info(
                    'clip text model size mismatch, downloading again',
                    localFileSize
                );
                textModelDownloadInProgress = true;
                downloadModel(modelSavePath, TEXT_MODEL_DOWNLOAD_URL[type])
                    .catch(() => {
                        // ignore
                    })
                    .finally(() => {
                        textModelDownloadInProgress = false;
                    });
                throw Error(CustomErrors.MODEL_DOWNLOAD_PENDING);
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

async function createOnnxSession(modelPath: string) {
    return await ort.InferenceSession.create(modelPath, {
        intraOpNumThreads: 1,
        enableCpuMemArena: false,
    });
}

let onnxImageSession: any = null;

async function getOnnxImageSession() {
    if (!onnxImageSession) {
        const clipModelPath = await getClipImageModelPath('onnx');
        onnxImageSession = createOnnxSession(clipModelPath);
    }
    return onnxImageSession;
}

let onnxTextSession: any = null;

async function getOnnxTextSession() {
    if (!onnxTextSession) {
        const clipModelPath = await getClipTextModelPath('onnx');
        onnxTextSession = createOnnxSession(clipModelPath);
    }
    return onnxTextSession;
}

export async function computeImageEmbedding(
    inputFilePath: string
): Promise<Float32Array> {
    const ggmlImageEmbedding = await computeGGMLImageEmbedding(inputFilePath);
    const onnxImageEmbedding = await computeONNXImageEmbedding(inputFilePath);
    const score = await computeClipMatchScore(
        ggmlImageEmbedding,
        onnxImageEmbedding
    );
    log.info('imageEmbeddingScore', score);
    return onnxImageEmbedding;
}

export async function computeGGMLImageEmbedding(
    inputFilePath: string
): Promise<Float32Array> {
    try {
        const clipModelPath = await getClipImageModelPath('ggml');
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
        throw err;
    }
}

export async function computeONNXImageEmbedding(
    inputFilePath: string
): Promise<Float32Array> {
    try {
        const imageSession = await getOnnxImageSession();
        const rgbData = await getRgbData(inputFilePath);
        const feeds = {
            input: new ort.Tensor('float32', rgbData, [1, 3, 224, 224]),
        };
        const results = await imageSession.run(feeds);
        const embedVec = results['output'].data; // Float32Array
        return embedVec;
    } catch (err) {
        logErrorSentry(err, 'Error in computeImageEmbedding');
        throw err;
    }
}

export async function computeTextEmbedding(
    inputFilePath: string
): Promise<Float32Array> {
    const ggmlTextEmbedding = await computeGGMLTextEmbedding(inputFilePath);
    const onnxTextEmbedding = await computeONNXTextEmbedding(inputFilePath);
    const score = await computeClipMatchScore(
        ggmlTextEmbedding,
        onnxTextEmbedding
    );
    console.log('textEmbeddingScore', score);
    return onnxTextEmbedding;
}

export async function computeGGMLTextEmbedding(
    text: string
): Promise<Float32Array> {
    try {
        const clipModelPath = await getClipTextModelPath('ggml');
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
        if (err.message === CustomErrors.MODEL_DOWNLOAD_PENDING) {
            log.info(CustomErrors.MODEL_DOWNLOAD_PENDING);
        } else {
            logErrorSentry(err, 'Error in computeTextEmbedding');
        }
        throw err;
    }
}

export async function computeONNXTextEmbedding(
    text: string
): Promise<Float32Array> {
    try {
        const imageSession = await getOnnxTextSession();
        const tokenizedText = Int32Array.from(encode(text));
        const feeds = {
            input: new ort.Tensor('int32', tokenizedText, [1, 77]),
        };
        const results = await imageSession.run(feeds);
        console.log('result', results);
        return new Float32Array();
    } catch (err) {
        if (err.message === CustomErrors.MODEL_DOWNLOAD_PENDING) {
            log.info(CustomErrors.MODEL_DOWNLOAD_PENDING);
        } else {
            logErrorSentry(err, 'Error in computeTextEmbedding');
        }
        throw err;
    }
}

async function getRgbData(inputFilePath: string) {
    const width = 224;
    const height = 224;
    // let blob = await fetch(imgUrl, {referrer:""}).then(r => r.blob());

    const img = new Image();
    img.src = inputFilePath;

    const canvas = createCanvas(width, height);
    const ctx = canvas.getContext('2d');

    // scale img to fit the shorter side to the canvas size
    const scale = Math.max(
        canvas.width / img.width,
        canvas.height / img.height
    );

    // compute new image dimensions that would maintain the original aspect ratio
    const scaledW = img.width * scale;
    const scaledH = img.height * scale;

    // compute position to center the image
    const posX = (canvas.width - scaledW) / 2;
    const posY = (canvas.height - scaledH) / 2;

    // draw the image centered and scaled on the canvas
    ctx.drawImage(img, posX, posY, scaledW, scaledH);

    const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
    const rgbData: [number[][], number[][], number[][]] = [[], [], []]; // [r, g, b]
    // remove alpha and put into correct shape:
    const d = imageData.data;
    for (let i = 0; i < d.length; i += 4) {
        const x = (i / 4) % width;
        const y = Math.floor(i / 4 / width);
        if (!rgbData[0][y]) rgbData[0][y] = [];
        if (!rgbData[1][y]) rgbData[1][y] = [];
        if (!rgbData[2][y]) rgbData[2][y] = [];
        rgbData[0][y][x] = d[i + 0] / 255;
        rgbData[1][y][x] = d[i + 1] / 255;
        rgbData[2][y][x] = d[i + 2] / 255;
        // From CLIP repo: Normalize(mean=(0.48145466, 0.4578275, 0.40821073), std=(0.26862954, 0.26130258, 0.27577711))
        rgbData[0][y][x] = (rgbData[0][y][x] - 0.48145466) / 0.26862954;
        rgbData[1][y][x] = (rgbData[1][y][x] - 0.4578275) / 0.26130258;
        rgbData[2][y][x] = (rgbData[2][y][x] - 0.40821073) / 0.27577711;
    }
    return Float32Array.from(rgbData.flat().flat());
}

export const computeClipMatchScore = async (
    imageEmbedding: Float32Array,
    textEmbedding: Float32Array
) => {
    if (imageEmbedding.length !== textEmbedding.length) {
        throw Error('imageEmbedding and textEmbedding length mismatch');
    }
    let score = 0;
    let imageNormalization = 0;
    let textNormalization = 0;

    for (let index = 0; index < imageEmbedding.length; index++) {
        imageNormalization += imageEmbedding[index] * imageEmbedding[index];
        textNormalization += textEmbedding[index] * textEmbedding[index];
    }
    for (let index = 0; index < imageEmbedding.length; index++) {
        imageEmbedding[index] =
            imageEmbedding[index] / Math.sqrt(imageNormalization);
        textEmbedding[index] =
            textEmbedding[index] / Math.sqrt(textNormalization);
    }
    for (let index = 0; index < imageEmbedding.length; index++) {
        score += imageEmbedding[index] * textEmbedding[index];
    }
    return score;
};
