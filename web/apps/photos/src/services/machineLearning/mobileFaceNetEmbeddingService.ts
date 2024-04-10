import log from "@/next/log";
import * as tf from "@tensorflow/tfjs-core";
import {
    MOBILEFACENET_EMBEDDING_SIZE,
    MOBILEFACENET_FACE_SIZE,
} from "constants/mlConfig";
// import { TFLiteModel } from "@tensorflow/tfjs-tflite";
// import PQueue from "p-queue";
import {
    FaceEmbedding,
    FaceEmbeddingMethod,
    FaceEmbeddingService,
    Versioned,
} from "types/machineLearning";

// TODO(MR): onnx-yolo
// import * as ort from "onnxruntime-web";
// import { env } from "onnxruntime-web";
const ort: any = {};

import {
    clamp,
    getPixelBilinear,
    normalizePixelBetweenMinus1And1,
} from "utils/image";

// TODO(MR): onnx-yolo
// env.wasm.wasmPaths = "/js/onnx/";
class MobileFaceNetEmbeddingService implements FaceEmbeddingService {
    // TODO(MR): onnx-yolo
    // private onnxInferenceSession?: ort.InferenceSession;
    private onnxInferenceSession?: any;
    public method: Versioned<FaceEmbeddingMethod>;
    public faceSize: number;

    public constructor(faceSize: number = MOBILEFACENET_FACE_SIZE) {
        this.method = {
            value: "MobileFaceNet",
            version: 2,
        };
        this.faceSize = faceSize;
        // TODO: set timeout
    }

    private async initOnnx() {
        console.log("start ort mobilefacenet");
        this.onnxInferenceSession = await ort.InferenceSession.create(
            "/models/mobilefacenet/mobilefacenet_opset15.onnx",
        );
        const faceBatchSize = 1;
        const data = new Float32Array(
            faceBatchSize * 3 * this.faceSize * this.faceSize,
        );
        const inputTensor = new ort.Tensor("float32", data, [
            faceBatchSize,
            this.faceSize,
            this.faceSize,
            3,
        ]);
        // TODO(MR): onnx-yolo
        // const feeds: Record<string, ort.Tensor> = {};
        const feeds: Record<string, any> = {};
        const name = this.onnxInferenceSession.inputNames[0];
        feeds[name] = inputTensor;
        await this.onnxInferenceSession.run(feeds);
        console.log("start end mobilefacenet");
    }

    private async getOnnxInferenceSession() {
        if (!this.onnxInferenceSession) {
            await this.initOnnx();
        }
        return this.onnxInferenceSession;
    }

    private preprocessImageBitmapToFloat32(
        imageBitmap: ImageBitmap,
        requiredWidth: number = this.faceSize,
        requiredHeight: number = this.faceSize,
        maintainAspectRatio: boolean = true,
        normFunction: (
            pixelValue: number,
        ) => number = normalizePixelBetweenMinus1And1,
    ) {
        // Create an OffscreenCanvas and set its size
        const offscreenCanvas = new OffscreenCanvas(
            imageBitmap.width,
            imageBitmap.height,
        );
        const ctx = offscreenCanvas.getContext("2d");
        ctx.drawImage(imageBitmap, 0, 0, imageBitmap.width, imageBitmap.height);
        const imageData = ctx.getImageData(
            0,
            0,
            imageBitmap.width,
            imageBitmap.height,
        );
        const pixelData = imageData.data;

        let scaleW = requiredWidth / imageBitmap.width;
        let scaleH = requiredHeight / imageBitmap.height;
        if (maintainAspectRatio) {
            const scale = Math.min(
                requiredWidth / imageBitmap.width,
                requiredHeight / imageBitmap.height,
            );
            scaleW = scale;
            scaleH = scale;
        }
        const scaledWidth = clamp(
            Math.round(imageBitmap.width * scaleW),
            0,
            requiredWidth,
        );
        const scaledHeight = clamp(
            Math.round(imageBitmap.height * scaleH),
            0,
            requiredHeight,
        );

        const processedImage = new Float32Array(
            1 * requiredWidth * requiredHeight * 3,
        );
        log.info("loaded mobileFaceNetModel: ", tf.getBackend());

        // Populate the Float32Array with normalized pixel values
        for (let h = 0; h < requiredHeight; h++) {
            for (let w = 0; w < requiredWidth; w++) {
                let pixel: {
                    r: number;
                    g: number;
                    b: number;
                };
                if (w >= scaledWidth || h >= scaledHeight) {
                    pixel = { r: 114, g: 114, b: 114 };
                } else {
                    pixel = getPixelBilinear(
                        w / scaleW,
                        h / scaleH,
                        pixelData,
                        imageBitmap.width,
                        imageBitmap.height,
                    );
                }
                const pixelIndex = 3 * (h * requiredWidth + w);
                processedImage[pixelIndex] = normFunction(pixel.r);
                processedImage[pixelIndex + 1] = normFunction(pixel.g);
                processedImage[pixelIndex + 2] = normFunction(pixel.b);
            }
        }

        return processedImage;
    }

    public async getFaceEmbeddings(
        faceData: Float32Array,
    ): Promise<Array<FaceEmbedding>> {
        const inputTensor = new ort.Tensor("float32", faceData, [
            Math.round(faceData.length / (this.faceSize * this.faceSize * 3)),
            this.faceSize,
            this.faceSize,
            3,
        ]);
        // TODO(MR): onnx-yolo
        // const feeds: Record<string, ort.Tensor> = {};
        const feeds: Record<string, any> = {};
        feeds["img_inputs"] = inputTensor;
        const inferenceSession = await this.getOnnxInferenceSession();
        // TODO(MR): onnx-yolo
        // const runout: ort.InferenceSession.OnnxValueMapType =
        const runout: any = await inferenceSession.run(feeds);
        // const test = runout.embeddings;
        // const test2 = test.cpuData;
        const outputData = runout.embeddings["cpuData"] as Float32Array;
        const embeddings = new Array<FaceEmbedding>(
            outputData.length / MOBILEFACENET_EMBEDDING_SIZE,
        );
        for (let i = 0; i < embeddings.length; i++) {
            embeddings[i] = new Float32Array(
                outputData.slice(
                    i * MOBILEFACENET_EMBEDDING_SIZE,
                    (i + 1) * MOBILEFACENET_EMBEDDING_SIZE,
                ),
            );
        }
        return embeddings;
    }

    public async dispose() {
        const inferenceSession = await this.getOnnxInferenceSession();
        inferenceSession?.release();
        this.onnxInferenceSession = undefined;
    }
}

export default new MobileFaceNetEmbeddingService();
