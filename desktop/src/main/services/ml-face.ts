/**
 * @file Various face recognition related tasks.
 *
 * - Face detection with the YOLO model.
 * - Face embedding with the mobilefacenet model.
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


// export const clipImageEmbedding = async (jpegImageData: Uint8Array) => {
//     const tempFilePath = await generateTempFilePath("");
//     const imageStream = new Response(jpegImageData.buffer).body;
//     await writeStream(tempFilePath, imageStream);
//     try {
//         return await clipImageEmbedding_(tempFilePath);
//     } finally {
//         await deleteTempFile(tempFilePath);
//     }
// };

// const clipImageEmbedding_ = async (jpegFilePath: string) => {
//     const imageSession = await onnxImageSession();
//     const t1 = Date.now();
//     const rgbData = await getRGBData(jpegFilePath);
//     const feeds = {
//         input: new ort.Tensor("float32", rgbData, [1, 3, 224, 224]),
//     };
//     const t2 = Date.now();
//     const results = await imageSession.run(feeds);
//     log.debug(
//         () =>
//             `CLIP image embedding took ${Date.now() - t1} ms (prep: ${t2 - t1} ms, inference: ${Date.now() - t2} ms)`,
//     );
//     const imageEmbedding = results["output"].data; // Float32Array
//     return normalizeEmbedding(imageEmbedding);
// };
