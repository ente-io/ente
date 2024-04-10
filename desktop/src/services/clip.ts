/**
 * @file Compute CLIP embeddings
 *
 * @see `web/apps/photos/src/services/clip-service.ts` for more details. This
 * file implements the Node.js implementation of the actual embedding
 * computation. By doing it in the Node.js layer, we can use the binary ONNX
 * runtimes which are 10-20x faster than the WASM based web ones.
 *
 * The embeddings are computed using ONNX runtime. The model itself is not
 * shipped with the app but is downloaded on demand.
 */
import { app, net } from "electron/main";
import { existsSync } from "fs";
import fs from "node:fs/promises";
import path from "node:path";
import { writeStream } from "../main/fs";
import log from "../main/log";
import { CustomErrors } from "../types/ipc";
import Tokenizer from "../utils/clip-bpe-ts/mod";
import { generateTempFilePath } from "../utils/temp";
import { deleteTempFile } from "./ffmpeg";
const jpeg = require("jpeg-js");
const ort = require("onnxruntime-node");

const textModelName = "clip-text-vit-32-uint8.onnx";
const textModelByteSize = 64173509; // 61.2 MB

const imageModelName = "clip-image-vit-32-float32.onnx";
const imageModelByteSize = 351468764; // 335.2 MB

/** Return the path where the given {@link modelName} is meant to be saved */
const modelSavePath = (modelName: string) =>
    path.join(app.getPath("userData"), "models", modelName);

const downloadModel = async (saveLocation: string, name: string) => {
    // `mkdir -p` the directory where we want to save the model.
    const saveDir = path.dirname(saveLocation);
    await fs.mkdir(saveDir, { recursive: true });
    // Download
    log.info(`Downloading CLIP model from ${name}`);
    const url = `https://models.ente.io/${name}`;
    const res = await net.fetch(url);
    if (!res.ok) throw new Error(`Failed to fetch ${url}: HTTP ${res.status}`);
    // Save
    await writeStream(saveLocation, res.body);
    log.info(`Downloaded CLIP model ${name}`);
};

let activeImageModelDownload: Promise<void> | undefined;

const imageModelPathDownloadingIfNeeded = async () => {
    try {
        const modelPath = modelSavePath(imageModelName);
        if (activeImageModelDownload) {
            log.info("Waiting for CLIP image model download to finish");
            await activeImageModelDownload;
        } else {
            if (!existsSync(modelPath)) {
                log.info("CLIP image model not found, downloading");
                activeImageModelDownload = downloadModel(
                    modelPath,
                    imageModelName,
                );
                await activeImageModelDownload;
            } else {
                const localFileSize = (await fs.stat(modelPath)).size;
                if (localFileSize !== imageModelByteSize) {
                    log.error(
                        `CLIP image model size ${localFileSize} does not match the expected size, downloading again`,
                    );
                    activeImageModelDownload = downloadModel(
                        modelPath,
                        imageModelName,
                    );
                    await activeImageModelDownload;
                }
            }
        }
        return modelPath;
    } finally {
        activeImageModelDownload = undefined;
    }
};

let textModelDownloadInProgress = false;

const textModelPathDownloadingIfNeeded = async () => {
    if (textModelDownloadInProgress)
        throw Error(CustomErrors.MODEL_DOWNLOAD_PENDING);

    const modelPath = modelSavePath(textModelName);
    if (!existsSync(modelPath)) {
        log.info("CLIP text model not found, downloading");
        textModelDownloadInProgress = true;
        downloadModel(modelPath, textModelName)
            .catch((e) => {
                // log but otherwise ignore
                log.error("CLIP text model download failed", e);
            })
            .finally(() => {
                textModelDownloadInProgress = false;
            });
        throw Error(CustomErrors.MODEL_DOWNLOAD_PENDING);
    } else {
        const localFileSize = (await fs.stat(modelPath)).size;
        if (localFileSize !== textModelByteSize) {
            log.error(
                `CLIP text model size ${localFileSize} does not match the expected size, downloading again`,
            );
            textModelDownloadInProgress = true;
            downloadModel(modelPath, textModelName)
                .catch((e) => {
                    // log but otherwise ignore
                    log.error("CLIP text model download failed", e);
                })
                .finally(() => {
                    textModelDownloadInProgress = false;
                });
            throw Error(CustomErrors.MODEL_DOWNLOAD_PENDING);
        }
    }

    return modelPath;
};

const createInferenceSession = async (modelPath: string) => {
    return await ort.InferenceSession.create(modelPath, {
        intraOpNumThreads: 1,
        enableCpuMemArena: false,
    });
};

let imageSessionPromise: Promise<any> | undefined;

const onnxImageSession = async () => {
    if (!imageSessionPromise) {
        imageSessionPromise = (async () => {
            const modelPath = await imageModelPathDownloadingIfNeeded();
            return createInferenceSession(modelPath);
        })();
    }
    return imageSessionPromise;
};

let _textSession: any = null;

const onnxTextSession = async () => {
    if (!_textSession) {
        const modelPath = await textModelPathDownloadingIfNeeded();
        _textSession = await createInferenceSession(modelPath);
    }
    return _textSession;
};

export const clipImageEmbedding = async (jpegImageData: Uint8Array) => {
    const tempFilePath = await generateTempFilePath("");
    const imageStream = new Response(jpegImageData.buffer).body;
    await writeStream(tempFilePath, imageStream);
    try {
        return await clipImageEmbedding_(tempFilePath);
    } finally {
        await deleteTempFile(tempFilePath);
    }
};

const clipImageEmbedding_ = async (jpegFilePath: string) => {
    const imageSession = await onnxImageSession();
    const t1 = Date.now();
    const rgbData = await getRGBData(jpegFilePath);
    const feeds = {
        input: new ort.Tensor("float32", rgbData, [1, 3, 224, 224]),
    };
    const t2 = Date.now();
    const results = await imageSession.run(feeds);
    log.debug(
        () =>
            `CLIP image embedding took ${Date.now() - t1} ms (prep: ${t2 - t1} ms, inference: ${Date.now() - t2} ms)`,
    );
    const imageEmbedding = results["output"].data; // Float32Array
    return normalizeEmbedding(imageEmbedding);
};

const getRGBData = async (jpegFilePath: string) => {
    const jpegData = await fs.readFile(jpegFilePath);
    const rawImageData = jpeg.decode(jpegData, {
        useTArray: true,
        formatAsRGBA: false,
    });

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
                // Linear interpolation
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

                // createTensorWithDataList is dumb compared to reshape and
                // hence has to be given with one channel after another
                const i: number = y * nx3 + x + (c % 3) * 224 * 224;

                result[i] = (v2 / 255 - mean[c]) / std[c];
            }
        }
    }

    return result;
};

const normalizeEmbedding = (embedding: Float32Array) => {
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

let _tokenizer: Tokenizer = null;
const getTokenizer = () => {
    if (!_tokenizer) {
        _tokenizer = new Tokenizer();
    }
    return _tokenizer;
};

export const clipTextEmbedding = async (text: string) => {
    const imageSession = await onnxTextSession();
    const t1 = Date.now();
    const tokenizer = getTokenizer();
    const tokenizedText = Int32Array.from(tokenizer.encodeForCLIP(text));
    const feeds = {
        input: new ort.Tensor("int32", tokenizedText, [1, 77]),
    };
    const t2 = Date.now();
    const results = await imageSession.run(feeds);
    log.debug(
        () =>
            `CLIP text embedding took ${Date.now() - t1} ms (prep: ${t2 - t1} ms, inference: ${Date.now() - t2} ms)`,
    );
    const textEmbedding = results["output"].data;
    return normalizeEmbedding(textEmbedding);
};
