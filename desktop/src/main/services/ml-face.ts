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
import { makeCachedInferenceSession } from "./ml";

const cachedFaceDetectionSession = makeCachedInferenceSession(
    "yolov5s_face_640_640_dynamic.onnx",
    30762872 /* 29.3 MB */,
);

export const detectFaces = async (input: Float32Array) => {
    const session = await cachedFaceDetectionSession();
    const t = Date.now();
    const feeds = {
        input: new ort.Tensor("float32", input, [1, 3, 640, 640]),
    };
    const results = await session.run(feeds);
    log.debug(() => `onnx/yolo face detection took ${Date.now() - t} ms`);
    return results["output"].data;
};

const cachedFaceEmbeddingSession = makeCachedInferenceSession(
    "mobilefacenet_opset15.onnx",
    5286998 /* 5 MB */,
);

export const faceEmbedding = async (input: Float32Array) => {
    // Dimension of each face (alias)
    const mobileFaceNetFaceSize = 112;
    // Smaller alias
    const z = mobileFaceNetFaceSize;
    // Size of each face's data in the batch
    const n = Math.round(input.length / (z * z * 3));
    const inputTensor = new ort.Tensor("float32", input, [n, z, z, 3]);

    const session = await cachedFaceEmbeddingSession();
    const t = Date.now();
    const feeds = { img_inputs: inputTensor };
    const results = await session.run(feeds);
    log.debug(() => `onnx/yolo face embedding took ${Date.now() - t} ms`);
    /* Need these model specific casts to extract and type the result */
    return (results.embeddings as unknown as any)["cpuData"] as Float32Array;
};
