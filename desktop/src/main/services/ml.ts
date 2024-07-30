/**
 * @file ML related functionality, generic layer.
 *
 * @see also `ml-clip.ts`, `ml-face.ts`.
 *
 * The ML runtime we use for inference is [ONNX](https://onnxruntime.ai). Models
 * for various tasks are not shipped with the app but are downloaded on demand.
 */

import { app, net } from "electron/main";
import { existsSync } from "fs";
import fs from "node:fs/promises";
import path from "node:path";
import * as ort from "onnxruntime-node";
import log from "../log";
import { writeStream } from "../stream";

/**
 * Create a new ML session.
 *
 * [Note: ML IPC]
 *
 * The primary reason for doing ML tasks in the Node.js layer is so that we can
 * use the binary ONNX runtime, which is 10-20x faster than the WASM one that
 * can be used directly on the web layer.
 *
 * For this to work, the main and renderer process need to communicate with each
 * other. Further, in the web layer the ML indexing runs in a web worker (so as
 * to not get in the way of the main thread). So the communication has 2 hops:
 *
 *     Node.js main <-> Renderer main <-> Renderer web worker
 *
 * This naive way works, but has a problem. The Node.js main process is in the
 * code path for delivering user events to the renderer process. The ML tasks we
 * do take in the order of 100-300 ms (possibly more) for each individual
 * inference. Thus, the Node.js main process is busy for those 100-300 ms, and
 * does not forward events to the renderer, causing the UI to jitter.
 *
 * The solution for this is to spawn an Electron UtilityProcess, which we can
 * think of a regular Node.js child process.  This frees up the Node.js main
 * process, and would remove the jitter.
 * https://www.electronjs.org/docs/latest/tutorial/process-model
 *
 * It would seem that this introduces another hop in our IPC
 *
 *     Node.js utility process <-> Node.js main <-> ...
 *
 * but here we can use the special bit about Electron utility processes that
 * separates them from regular Node.js child processes: their support for
 * message ports. https://www.electronjs.org/docs/latest/tutorial/message-ports
 *
 * As a brief summary, a MessagePort is a web feature that allows two contexts
 * to communicate. A pair of message ports is called a message channel. The cool
 * thing about these is that we can pass these ports themselves over IPC.
 *
 * So we
 *
 * 1.  Spawn a utility process.
 * 2.  In the utility process create a message channel.
 * 3.  Keep one port of the pair with us, and send the other over IPC to the
 *     _web worker_ that is coordinating the ML indexing on the web layer.
 *
 * Thereafter, the utility process and web worker can directly talk to each
 * other!
 *
 *     Node.js utility process <-> Renderer web worker
 *
 */
export const createMLSession = () => {
    // }: Promise<MessagePort> => {
    throw new Error("Not implemented");
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
 * Crete an ONNX {@link InferenceSession} with some defaults.
 */
const createInferenceSession = async (modelPath: string) => {
    return await ort.InferenceSession.create(modelPath, {
        // Restrict the number of threads to 1.
        intraOpNumThreads: 1,
        // Be more conservative with RAM usage.
        enableCpuMemArena: false,
    });
};
