/**
 * @file ML related tasks. This code runs in a utility process.
 *
 * The ML runtime we use for inference is [ONNX](https://onnxruntime.ai). Models
 * for various tasks are not shipped with the app but are downloaded on demand.
 */

// See [Note: Using Electron APIs in UtilityProcess] about what we can and
// cannot import.

import Tokenizer from "clip-bpe-js";
import { expose } from "comlink";
import { net } from "electron/main";
import { existsSync } from "fs";
import fs from "node:fs/promises";
import path from "node:path";
import * as ort from "onnxruntime-node";
import { z } from "zod/v4";
import log from "../log-worker";
import { messagePortMainEndpoint } from "../utils/comlink";
import { wait } from "../utils/common";
import { writeStream } from "../utils/stream";
import { fsStatMtime } from "./fs";

log.debugString("Started ML utility process");

process.on("uncaughtException", (e, origin) => log.error(origin, e));

process.parentPort.once("message", (e) => {
    // Initialize ourselves with the data we got from our parent.
    parseInitData(e.data);
    // Expose an instance of `ElectronMLWorker` on the port we got from our
    // parent.
    expose(
        {
            fsStatMtime,
            computeCLIPImageEmbedding,
            computeCLIPTextEmbeddingIfAvailable,
            detectFaces,
            computeFaceEmbeddings,
        },
        messagePortMainEndpoint(e.ports[0]!),
    );
});

/**
 * We cannot access Electron's {@link app} object within a utility process, so
 * we pass the value of `app.getPath("userData")` during initialization, and it
 * can be subsequently retrieved from here.
 */
let _userDataPath: string | undefined;

/** Equivalent to app.getPath("userData") */
const userDataPath = () => _userDataPath!;

const MLWorkerInitData = z.object({ userDataPath: z.string() });

const parseInitData = (data: unknown) => {
    _userDataPath = MLWorkerInitData.parse(data).userDataPath;
};

/**
 * Return a function that can be used to trigger a download of the specified
 * model, and the creating of an ONNX inference session initialized using it.
 *
 * Multiple parallel calls to the returned function are fine, it ensures that
 * the the model will be downloaded and the session created using it only once.
 * All pending calls to it meanwhile will just await on the same promise.
 *
 * And once the promise is resolved, the create ONNX inference session will be
 * cached, so subsequent calls to the returned function will just reuse the same
 * session.
 *
 * {@link makeCachedInferenceSession} can itself be called anytime, it doesn't
 * actively trigger a download until the returned function is called.
 *
 * @param modelName The name of the model to download.
 *
 * @param modelByteSize The size in bytes that we expect the model to have. If
 * the size of the downloaded model does not match the expected size, then we
 * will redownload it.
 *
 * @returns a function. calling that function returns a promise to an ONNX
 * session.
 */
const makeCachedInferenceSession = (
    modelName: string,
    modelByteSize: number,
) => {
    let session: Promise<ort.InferenceSession> | undefined;

    const download = () =>
        modelPathDownloadingIfNeeded(modelName, modelByteSize);

    const createSession = (modelPath: string) =>
        createInferenceSession(modelPath);

    const cachedInferenceSession = () =>
        (session ??= download().then(createSession));

    return cachedInferenceSession;
};

/**
 * Download the model named {@link modelName} if we don't already have it.
 *
 * Also verify that the size of the model we get matches {@expectedByteSize} (if
 * not, redownload it).
 *
 * @returns the path to the model on the local machine.
 */
const modelPathDownloadingIfNeeded = async (
    modelName: string,
    expectedByteSize: number,
) => {
    const modelPath = modelSavePath(modelName);

    await cleanupOldModelsIfNeeded();

    if (!existsSync(modelPath)) {
        log.info("CLIP image model not found, downloading");
        await downloadModel(modelPath, modelName);
    } else {
        const size = (await fs.stat(modelPath)).size;
        if (size !== expectedByteSize) {
            log.error(
                `The size ${size} of model ${modelName} does not match the expected size, downloading again`,
            );
            await downloadModel(modelPath, modelName);
        }
    }

    return modelPath;
};

/**
 * Cleanup old models.
 *
 * This code runs whenever we need to download a new model, which usually
 * happens when we update a model, so this is a great time to go through the
 * list of previously existent but now unused models, and delete them if they
 * exist to clean up the user's disk space.
 */
const cleanupOldModelsIfNeeded = async () => {
    const oldModelNames = [
        "clip-image-vit-32-float32.onnx",
        "clip-text-vit-32-uint8.onnx",
        "mobileclip_s2_image.onnx",
        "mobileclip_s2_image_opset18_rgba_sim.onnx",
        "mobileclip_s2_text_int32.onnx",
        "yolov5s_face_640_640_dynamic.onnx",
        "yolov5s_face_opset18_rgba_opt.onnx",
    ];

    for (const modelName of oldModelNames) {
        const modelPath = modelSavePath(modelName);
        if (existsSync(modelPath)) {
            log.info(`Removing unused ML model at ${modelPath}`);
            await fs.rm(modelPath);
        }
    }
};

/** Return the path where the given {@link modelName} is meant to be saved */
const modelSavePath = (modelName: string) =>
    path.join(userDataPath(), "models", modelName);

const downloadModel = async (saveLocation: string, name: string) => {
    // `mkdir -p` the directory where we want to save the model.
    const saveDir = path.dirname(saveLocation);
    await fs.mkdir(saveDir, { recursive: true });
    // Download.
    log.info(`Downloading ML model from ${name}`);
    const url = `https://models.ente.io/${name}`;
    const res = await net.fetch(url);
    if (!res.ok) throw new Error(`Failed to fetch ${url}: HTTP ${res.status}`);
    const body = res.body;
    if (!body) throw new Error(`Received an null response for ${url}`);
    // Save.
    await writeStream(saveLocation, body);
    log.info(`Downloaded CLIP model ${name}`);
};

/**
 * Create an ONNX {@link InferenceSession} with some defaults.
 */
const createInferenceSession = (modelPath: string) =>
    ort.InferenceSession.create(modelPath, {
        // Restrict the number of threads to 1.
        intraOpNumThreads: 1,
        // Be more conservative with RAM usage.
        enableCpuMemArena: false,
    });

const cachedCLIPImageSession = makeCachedInferenceSession(
    "mobileclip_s2_image_opset18_rgba_opt.onnx",
    143099752 /* 143 MB */,
);

/**
 * Compute CLIP embeddings for an image.
 *
 * The embeddings are computed using ONNX runtime, with MobileCLIP as the model.
 */
export const computeCLIPImageEmbedding = async (
    input: Uint8ClampedArray,
    inputShape: number[],
) => {
    const session = await cachedCLIPImageSession();
    const inputArray = new Uint8Array(input.buffer);
    const feeds = { input: new ort.Tensor("uint8", inputArray, inputShape) };
    const t = Date.now();
    const results = await session.run(feeds);
    log.debugString(`ONNX/CLIP image embedding took ${Date.now() - t} ms`);
    /* Need these model specific casts to type the result */
    return results.output!.data as Float32Array;
};

const cachedCLIPTextSession = makeCachedInferenceSession(
    "mobileclip_s2_text_opset18_quant.onnx",
    67144712 /* 67 MB */,
);

let _tokenizer: Tokenizer | undefined;
const getTokenizer = () => (_tokenizer ??= new Tokenizer());

/**
 * Compute CLIP embeddings for an text snippet.
 *
 * The embeddings are computed using ONNX runtime, with MobileCLIP as the model.
 */
export const computeCLIPTextEmbeddingIfAvailable = async (text: string) => {
    const sessionOrSkip = await Promise.race([
        cachedCLIPTextSession(),
        // Wait a bit to get the session promise to resolved the first time this
        // code runs on each app start (in these cases the model will already be
        // downloaded, so session creation should take only a 1 or 2 ticks: file
        // system stat, and ort.InferenceSession.create).
        wait(50).then(() => 1),
    ]);

    // Don't wait for the download to complete.
    if (typeof sessionOrSkip == "number") {
        log.info(
            "Ignoring CLIP text embedding request because model download is pending",
        );
        return undefined;
    }

    const session = sessionOrSkip;
    const tokenizer = getTokenizer();
    const tokenizedText = Int32Array.from(tokenizer.encodeForCLIP(text));
    const feeds = { input: new ort.Tensor("int32", tokenizedText, [1, 77]) };

    const t = Date.now();
    const results = await session.run(feeds);
    log.debugString(`ONNX/CLIP text embedding took ${Date.now() - t} ms`);
    return results.output!.data as Float32Array;
};

const cachedFaceDetectionSession = makeCachedInferenceSession(
    "yolov5s_face_opset18_rgba_opt_nosplits.onnx",
    28952651 /* 29 MB */,
);

/**
 * Face detection with the YOLO model and ONNX runtime.
 */
export const detectFaces = async (
    input: Uint8ClampedArray,
    inputShape: number[],
) => {
    const session = await cachedFaceDetectionSession();
    const inputArray = new Uint8Array(input.buffer);
    const feeds = { input: new ort.Tensor("uint8", inputArray, inputShape) };
    const t = Date.now();
    const results = await session.run(feeds);
    log.debugString(`ONNX/YOLO face detection took ${Date.now() - t} ms`);
    return results.output!.data;
};

const cachedFaceEmbeddingSession = makeCachedInferenceSession(
    "mobilefacenet_opset15.onnx",
    5286998 /* 5 MB */,
);

/**
 * Face embedding with the MobileFaceNet model and ONNX runtime.
 */
export const computeFaceEmbeddings = async (input: Float32Array) => {
    // Dimension of each face (alias)
    const mobileFaceNetFaceSize = 112;
    // Smaller alias
    const z = mobileFaceNetFaceSize;
    // Size of each face's data in the batch
    const n = Math.round(input.length / (z * z * 3));
    const inputTensor = new ort.Tensor("float32", input, [n, z, z, 3]);

    const session = await cachedFaceEmbeddingSession();
    const feeds = { img_inputs: inputTensor };
    const t = Date.now();
    const results = await session.run(feeds);
    log.debugString(`ONNX/MFNT face embedding took ${Date.now() - t} ms`);
    /* Need these model specific casts to extract and type the result */
    return (results.embeddings as unknown as Record<string, unknown>)
        .cpuData as Float32Array;
};
