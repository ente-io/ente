/**
 * @file Various face recognition related tasks.
 *
 * - Face detection with the YOLO model.
 * - Face embedding with the MobileFaceNet model.
 *
 * The runtime used is ONNX.
 */
import * as ort from "onnxruntime-node";
import log from "../log";
import { createInferenceSession, modelPathDownloadingIfNeeded } from "./ml";

const faceDetectionModelName = "yolov5s_face_640_640_dynamic.onnx";
const faceDetectionModelByteSize = 30762872; // 29.3 MB

const faceEmbeddingModelName = "mobilefacenet_opset15.onnx";
const faceEmbeddingModelByteSize = 5286998; // 5 MB

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
const makeCachedInferenceSession = (
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

let activeFaceDetectionModelDownload: Promise<string> | undefined;

const faceDetectionModelPathDownloadingIfNeeded = async () => {
    try {
        if (activeFaceDetectionModelDownload) {
            log.info("Waiting for face detection model download to finish");
            await activeFaceDetectionModelDownload;
        } else {
            activeFaceDetectionModelDownload = modelPathDownloadingIfNeeded(
                faceDetectionModelName,
                faceDetectionModelByteSize,
            );
            return await activeFaceDetectionModelDownload;
        }
    } finally {
        activeFaceDetectionModelDownload = undefined;
    }
};

let _faceDetectionSession: Promise<ort.InferenceSession> | undefined;

const faceDetectionSession = async () => {
    if (!_faceDetectionSession) {
        _faceDetectionSession =
            faceDetectionModelPathDownloadingIfNeeded().then((modelPath) =>
                createInferenceSession(modelPath),
            );
    }
    return _faceDetectionSession;
};

let activeFaceEmbeddingModelDownload: Promise<string> | undefined;

const faceEmbeddingModelPathDownloadingIfNeeded = async () => {
    try {
        if (activeFaceEmbeddingModelDownload) {
            log.info("Waiting for face embedding model download to finish");
            await activeFaceEmbeddingModelDownload;
        } else {
            activeFaceEmbeddingModelDownload = modelPathDownloadingIfNeeded(
                faceEmbeddingModelName,
                faceEmbeddingModelByteSize,
            );
            return await activeFaceEmbeddingModelDownload;
        }
    } finally {
        activeFaceEmbeddingModelDownload = undefined;
    }
};

let _faceEmbeddingSession: Promise<ort.InferenceSession> | undefined;

const faceEmbeddingSession = async () => {
    if (!_faceEmbeddingSession) {
        _faceEmbeddingSession =
            faceEmbeddingModelPathDownloadingIfNeeded().then((modelPath) =>
                createInferenceSession(modelPath),
            );
    }
    return _faceEmbeddingSession;
};

export const detectFaces = async (input: Float32Array) => {
    const session = await faceDetectionSession();
    const t = Date.now();
    const feeds = {
        input: new ort.Tensor("float32", input, [1, 3, 640, 640]),
    };
    const results = await session.run(feeds);
    log.debug(() => `onnx/yolo face detection took ${Date.now() - t} ms`);
    return results["output"].data;
};

export const faceEmbedding = async (input: Float32Array) => {
    // Dimension of each face (alias)
    const mobileFaceNetFaceSize = 112;
    // Smaller alias
    const z = mobileFaceNetFaceSize;
    // Size of each face's data in the batch
    const n = Math.round(input.length / (z * z * 3));
    const inputTensor = new ort.Tensor("float32", input, [n, z, z, 3]);

    const session = await faceEmbeddingSession();
    const t = Date.now();
    const feeds = { img_inputs: inputTensor };
    const results = await session.run(feeds);
    log.debug(() => `onnx/yolo face embedding took ${Date.now() - t} ms`);
    // TODO: What's with this type? It works in practice, but double check.
    return (results.embeddings as unknown as any)["cpuData"]; // as Float32Array;
};
