import { app, net } from "electron/main";
import { existsSync } from "fs";
import fs from "node:fs/promises";
import path from "node:path";
import { CustomErrors } from "../constants/errors";
import { writeStream } from "../main/fs";
import log, { logErrorSentry } from "../main/log";
import { execAsync, isDev } from "../main/util";
import { Model } from "../types/ipc";
import Tokenizer from "../utils/clip-bpe-ts/mod";
import { getPlatform } from "../utils/common/platform";
import { generateTempFilePath } from "../utils/temp";
import { deleteTempFile } from "./ffmpeg";
const jpeg = require("jpeg-js");

const CLIP_MODEL_PATH_PLACEHOLDER = "CLIP_MODEL";
const GGMLCLIP_PATH_PLACEHOLDER = "GGML_PATH";
const INPUT_PATH_PLACEHOLDER = "INPUT";

const IMAGE_EMBEDDING_EXTRACT_CMD: string[] = [
    GGMLCLIP_PATH_PLACEHOLDER,
    "-mv",
    CLIP_MODEL_PATH_PLACEHOLDER,
    "--image",
    INPUT_PATH_PLACEHOLDER,
];

const TEXT_EMBEDDING_EXTRACT_CMD: string[] = [
    GGMLCLIP_PATH_PLACEHOLDER,
    "-mt",
    CLIP_MODEL_PATH_PLACEHOLDER,
    "--text",
    INPUT_PATH_PLACEHOLDER,
];
const ort = require("onnxruntime-node");

const TEXT_MODEL_DOWNLOAD_URL = {
    ggml: "https://models.ente.io/clip-vit-base-patch32_ggml-text-model-f16.gguf",
    onnx: "https://models.ente.io/clip-text-vit-32-uint8.onnx",
};
const IMAGE_MODEL_DOWNLOAD_URL = {
    ggml: "https://models.ente.io/clip-vit-base-patch32_ggml-vision-model-f16.gguf",
    onnx: "https://models.ente.io/clip-image-vit-32-float32.onnx",
};

const TEXT_MODEL_NAME = {
    ggml: "clip-vit-base-patch32_ggml-text-model-f16.gguf",
    onnx: "clip-text-vit-32-uint8.onnx",
};
const IMAGE_MODEL_NAME = {
    ggml: "clip-vit-base-patch32_ggml-vision-model-f16.gguf",
    onnx: "clip-image-vit-32-float32.onnx",
};

const IMAGE_MODEL_SIZE_IN_BYTES = {
    ggml: 175957504, // 167.8 MB
    onnx: 351468764, // 335.2 MB
};
const TEXT_MODEL_SIZE_IN_BYTES = {
    ggml: 127853440, // 121.9 MB,
    onnx: 64173509, // 61.2 MB
};

/** Return the path where the given {@link modelName} is meant to be saved */
const getModelSavePath = (modelName: string) =>
    path.join(app.getPath("userData"), "models", modelName);

async function downloadModel(saveLocation: string, url: string) {
    // confirm that the save location exists
    const saveDir = path.dirname(saveLocation);
    await fs.mkdir(saveDir, { recursive: true });
    log.info("downloading clip model");
    const res = await net.fetch(url);
    if (!res.ok) throw new Error(`Failed to fetch ${url}: HTTP ${res.status}`);
    await writeStream(saveLocation, res.body);
    log.info("clip model downloaded");
}

let imageModelDownloadInProgress: Promise<void> = null;

export async function getClipImageModelPath(type: "ggml" | "onnx") {
    try {
        const modelSavePath = getModelSavePath(IMAGE_MODEL_NAME[type]);
        if (imageModelDownloadInProgress) {
            log.info("waiting for image model download to finish");
            await imageModelDownloadInProgress;
        } else {
            if (!existsSync(modelSavePath)) {
                log.info("clip image model not found, downloading");
                imageModelDownloadInProgress = downloadModel(
                    modelSavePath,
                    IMAGE_MODEL_DOWNLOAD_URL[type],
                );
                await imageModelDownloadInProgress;
            } else {
                const localFileSize = (await fs.stat(modelSavePath)).size;
                if (localFileSize !== IMAGE_MODEL_SIZE_IN_BYTES[type]) {
                    log.info(
                        `clip image model size mismatch, downloading again got: ${localFileSize}`,
                    );
                    imageModelDownloadInProgress = downloadModel(
                        modelSavePath,
                        IMAGE_MODEL_DOWNLOAD_URL[type],
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

export async function getClipTextModelPath(type: "ggml" | "onnx") {
    const modelSavePath = getModelSavePath(TEXT_MODEL_NAME[type]);
    if (textModelDownloadInProgress) {
        throw Error(CustomErrors.MODEL_DOWNLOAD_PENDING);
    } else {
        if (!existsSync(modelSavePath)) {
            log.info("clip text model not found, downloading");
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
                    `clip text model size mismatch, downloading again got: ${localFileSize}`,
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
        ? path.join("./build", `ggmlclip-${getPlatform()}`)
        : path.join(process.resourcesPath, `ggmlclip-${getPlatform()}`);
}

async function createOnnxSession(modelPath: string) {
    return await ort.InferenceSession.create(modelPath, {
        intraOpNumThreads: 1,
        enableCpuMemArena: false,
    });
}

let onnxImageSessionPromise: Promise<any> = null;

async function getOnnxImageSession() {
    if (!onnxImageSessionPromise) {
        onnxImageSessionPromise = (async () => {
            const clipModelPath = await getClipImageModelPath("onnx");
            return createOnnxSession(clipModelPath);
        })();
    }
    return onnxImageSessionPromise;
}

let onnxTextSession: any = null;

async function getOnnxTextSession() {
    if (!onnxTextSession) {
        const clipModelPath = await getClipTextModelPath("onnx");
        onnxTextSession = await createOnnxSession(clipModelPath);
    }
    return onnxTextSession;
}

let tokenizer: Tokenizer = null;
function getTokenizer() {
    if (!tokenizer) {
        tokenizer = new Tokenizer();
    }
    return tokenizer;
}

export const computeImageEmbedding = async (
    model: Model,
    imageData: Uint8Array,
): Promise<Float32Array> => {
    let tempInputFilePath = null;
    try {
        tempInputFilePath = await generateTempFilePath("");
        const imageStream = new Response(imageData.buffer).body;
        await writeStream(tempInputFilePath, imageStream);
        const embedding = await computeImageEmbedding_(
            model,
            tempInputFilePath,
        );
        return embedding;
    } catch (err) {
        if (isExecError(err)) {
            const parsedExecError = parseExecError(err);
            throw Error(parsedExecError);
        } else {
            throw err;
        }
    } finally {
        if (tempInputFilePath) {
            await deleteTempFile(tempInputFilePath);
        }
    }
};

const isExecError = (err: any) => {
    return err.message.includes("Command failed:");
};

const parseExecError = (err: any) => {
    const errMessage = err.message;
    if (errMessage.includes("Bad CPU type in executable")) {
        return CustomErrors.UNSUPPORTED_PLATFORM(
            process.platform,
            process.arch,
        );
    } else {
        return errMessage;
    }
};

async function computeImageEmbedding_(
    model: Model,
    inputFilePath: string,
): Promise<Float32Array> {
    if (!existsSync(inputFilePath)) {
        throw Error(CustomErrors.INVALID_FILE_PATH);
    }
    if (model === Model.GGML_CLIP) {
        return await computeGGMLImageEmbedding(inputFilePath);
    } else if (model === Model.ONNX_CLIP) {
        return await computeONNXImageEmbedding(inputFilePath);
    } else {
        throw Error(CustomErrors.INVALID_CLIP_MODEL(model));
    }
}

export async function computeGGMLImageEmbedding(
    inputFilePath: string,
): Promise<Float32Array> {
    try {
        const clipModelPath = await getClipImageModelPath("ggml");
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

        const { stdout } = await execAsync(cmd);
        // parse stdout and return embedding
        // get the last line of stdout
        const lines = stdout.split("\n");
        const lastLine = lines[lines.length - 1];
        const embedding = JSON.parse(lastLine);
        const embeddingArray = new Float32Array(embedding);
        return embeddingArray;
    } catch (err) {
        log.error("Failed to compute GGML image embedding", err);
        throw err;
    }
}

export async function computeONNXImageEmbedding(
    inputFilePath: string,
): Promise<Float32Array> {
    try {
        const imageSession = await getOnnxImageSession();
        const t1 = Date.now();
        const rgbData = await getRGBData(inputFilePath);
        const feeds = {
            input: new ort.Tensor("float32", rgbData, [1, 3, 224, 224]),
        };
        const t2 = Date.now();
        const results = await imageSession.run(feeds);
        log.info(
            `onnx image embedding time: ${Date.now() - t1} ms (prep:${
                t2 - t1
            } ms, extraction: ${Date.now() - t2} ms)`,
        );
        const imageEmbedding = results["output"].data; // Float32Array
        return normalizeEmbedding(imageEmbedding);
    } catch (err) {
        log.error("Failed to compute ONNX image embedding", err);
        throw err;
    }
}

export async function computeTextEmbedding(
    model: Model,
    text: string,
): Promise<Float32Array> {
    try {
        const embedding = computeTextEmbedding_(model, text);
        return embedding;
    } catch (err) {
        if (isExecError(err)) {
            const parsedExecError = parseExecError(err);
            throw Error(parsedExecError);
        } else {
            throw err;
        }
    }
}

async function computeTextEmbedding_(
    model: Model,
    text: string,
): Promise<Float32Array> {
    if (model === Model.GGML_CLIP) {
        return await computeGGMLTextEmbedding(text);
    } else {
        return await computeONNXTextEmbedding(text);
    }
}

export async function computeGGMLTextEmbedding(
    text: string,
): Promise<Float32Array> {
    try {
        const clipModelPath = await getClipTextModelPath("ggml");
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

        const { stdout } = await execAsync(cmd);
        // parse stdout and return embedding
        // get the last line of stdout
        const lines = stdout.split("\n");
        const lastLine = lines[lines.length - 1];
        const embedding = JSON.parse(lastLine);
        const embeddingArray = new Float32Array(embedding);
        return embeddingArray;
    } catch (err) {
        if (err.message === CustomErrors.MODEL_DOWNLOAD_PENDING) {
            log.info(CustomErrors.MODEL_DOWNLOAD_PENDING);
        } else {
            log.error("Failed to compute GGML text embedding", err);
        }
        throw err;
    }
}

export async function computeONNXTextEmbedding(
    text: string,
): Promise<Float32Array> {
    try {
        const imageSession = await getOnnxTextSession();
        const t1 = Date.now();
        const tokenizer = getTokenizer();
        const tokenizedText = Int32Array.from(tokenizer.encodeForCLIP(text));
        const feeds = {
            input: new ort.Tensor("int32", tokenizedText, [1, 77]),
        };
        const t2 = Date.now();
        const results = await imageSession.run(feeds);
        log.info(
            `onnx text embedding time: ${Date.now() - t1} ms (prep:${
                t2 - t1
            } ms, extraction: ${Date.now() - t2} ms)`,
        );
        const textEmbedding = results["output"].data; // Float32Array
        return normalizeEmbedding(textEmbedding);
    } catch (err) {
        if (err.message === CustomErrors.MODEL_DOWNLOAD_PENDING) {
            log.info(CustomErrors.MODEL_DOWNLOAD_PENDING);
        } else {
            logErrorSentry(err, "Error in computeONNXTextEmbedding");
        }
        throw err;
    }
}

async function getRGBData(inputFilePath: string) {
    const jpegData = await fs.readFile(inputFilePath);
    let rawImageData;
    try {
        rawImageData = jpeg.decode(jpegData, {
            useTArray: true,
            formatAsRGBA: false,
        });
    } catch (err) {
        logErrorSentry(err, "JPEG decode error");
        throw err;
    }

    const nx: number = rawImageData.width;
    const ny: number = rawImageData.height;
    const inputImage: Uint8Array = rawImageData.data;

    const nx2: number = 224;
    const ny2: number = 224;
    const totalSize: number = 3 * nx2 * ny2;

    const result: number[] = Array(totalSize).fill(0);
    const scale: number = Math.max(nx, ny) / 224;

    const nx3: number = Math.round(nx / scale);
    const ny3: number = Math.round(ny / scale);

    const mean: number[] = [0.48145466, 0.4578275, 0.40821073];
    const std: number[] = [0.26862954, 0.26130258, 0.27577711];

    for (let y = 0; y < ny3; y++) {
        for (let x = 0; x < nx3; x++) {
            for (let c = 0; c < 3; c++) {
                // linear interpolation
                const sx: number = (x + 0.5) * scale - 0.5;
                const sy: number = (y + 0.5) * scale - 0.5;

                const x0: number = Math.max(0, Math.floor(sx));
                const y0: number = Math.max(0, Math.floor(sy));

                const x1: number = Math.min(x0 + 1, nx - 1);
                const y1: number = Math.min(y0 + 1, ny - 1);

                const dx: number = sx - x0;
                const dy: number = sy - y0;

                const j00: number = 3 * (y0 * nx + x0) + c;
                const j01: number = 3 * (y0 * nx + x1) + c;
                const j10: number = 3 * (y1 * nx + x0) + c;
                const j11: number = 3 * (y1 * nx + x1) + c;

                const v00: number = inputImage[j00];
                const v01: number = inputImage[j01];
                const v10: number = inputImage[j10];
                const v11: number = inputImage[j11];

                const v0: number = v00 * (1 - dx) + v01 * dx;
                const v1: number = v10 * (1 - dx) + v11 * dx;

                const v: number = v0 * (1 - dy) + v1 * dy;

                const v2: number = Math.min(Math.max(Math.round(v), 0), 255);

                // createTensorWithDataList is dump compared to reshape and hence has to be given with one channel after another
                const i: number = y * nx3 + x + (c % 3) * 224 * 224;

                result[i] = (v2 / 255 - mean[c]) / std[c];
            }
        }
    }

    return result;
}

export const computeClipMatchScore = async (
    imageEmbedding: Float32Array,
    textEmbedding: Float32Array,
) => {
    if (imageEmbedding.length !== textEmbedding.length) {
        throw Error("imageEmbedding and textEmbedding length mismatch");
    }
    let score = 0;
    for (let index = 0; index < imageEmbedding.length; index++) {
        score += imageEmbedding[index] * textEmbedding[index];
    }
    return score;
};

export const normalizeEmbedding = (embedding: Float32Array) => {
    let normalization = 0;
    for (let index = 0; index < embedding.length; index++) {
        normalization += embedding[index] * embedding[index];
    }
    const sqrtNormalization = Math.sqrt(normalization);
    for (let index = 0; index < embedding.length; index++) {
        embedding[index] = embedding[index] / sqrtNormalization;
    }
    return embedding;
};
