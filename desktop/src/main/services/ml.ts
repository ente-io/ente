/**
 * @file AI/ML related functionality, generic layer.
 *
 * @see also `ml-clip.ts`, `ml-face.ts`.
 *
 * The ML runtime we use for inference is [ONNX](https://onnxruntime.ai). Models
 * for various tasks are not shipped with the app but are downloaded on demand.
 *
 * The primary reason for doing these tasks in the Node.js layer is so that we
 * can use the binary ONNX runtime which is 10-20x faster than the WASM based
 * web one.
 */
import { app, net } from "electron/main";
import { existsSync } from "fs";
import fs from "node:fs/promises";
import path from "node:path";
import * as ort from "onnxruntime-node";
import log from "../log";
import { writeStream } from "../stream";

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
 * @param modelByteSize The size in bytes that we expect the model to have. If
 * the size of the downloaded model does not match the expected size, then we
 * will redownload it.
 *
 * @returns a function. calling that function returns a promise to an ONNX
 * session.
 */
export const makeCachedInferenceSession = (
    modelName: string,
    modelByteSize: number,
) => {
    let session: Promise<ort.InferenceSession> | undefined;

    const download = () =>
        modelPathDownloadingIfNeeded(modelName, modelByteSize);

    const createSession = (modelPath: string) =>
        createInferenceSession(modelPath);

    const cachedInferenceSession = () => {
        if (!session) session = download().then(createSession);
        return session;
    };

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

/** Return the path where the given {@link modelName} is meant to be saved */
const modelSavePath = (modelName: string) =>
    path.join(app.getPath("userData"), "models", modelName);

const downloadModel = async (saveLocation: string, name: string) => {
    // `mkdir -p` the directory where we want to save the model.
    const saveDir = path.dirname(saveLocation);
    await fs.mkdir(saveDir, { recursive: true });
    // Download
    log.info(`Downloading ML model from ${name}`);
    const url = `https://models.ente.io/${name}`;
    const res = await net.fetch(url);
    if (!res.ok) throw new Error(`Failed to fetch ${url}: HTTP ${res.status}`);
    // Save
    await writeStream(saveLocation, res.body);
    log.info(`Downloaded CLIP model ${name}`);
};

/**
 * Crete an ONNX {@link InferenceSession} with some defaults.
 */
const createInferenceSession = async (modelPath: string) => {
    return await ort.InferenceSession.create(modelPath, {
        // Restrict the number of threads to 1
        intraOpNumThreads: 1,
        // Be more conservative with RAM usage
        enableCpuMemArena: false,
    });
};
