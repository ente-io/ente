import {
    BLAZEFACE_FACE_SIZE,
    MAX_FACE_DISTANCE_PERCENT,
} from "constants/mlConfig";
import { Dimensions } from "types/image";
import {
    FaceDetection,
    FaceDetectionMethod,
    FaceDetectionService,
    Versioned,
} from "types/machineLearning";
import {
    clamp,
    getPixelBilinear,
    normalizePixelBetween0And1,
} from "utils/image";
import { newBox } from "utils/machineLearning";
import { removeDuplicateDetections } from "utils/machineLearning/faceDetection";
import {
    computeTransformToBox,
    transformBox,
    transformPoints,
} from "utils/machineLearning/transform";
import { Box, Point } from "../../../thirdparty/face-api/classes";

// TODO(MR): onnx-yolo
// import * as ort from "onnxruntime-web";
// import { env } from "onnxruntime-web";
const ort: any = {};

// TODO(MR): onnx-yolo
// env.wasm.wasmPaths = "/js/onnx/";
class YoloFaceDetectionService implements FaceDetectionService {
    // TODO(MR): onnx-yolo
    // private onnxInferenceSession?: ort.InferenceSession;
    private onnxInferenceSession?: any;
    public method: Versioned<FaceDetectionMethod>;
    private desiredFaceSize;

    public constructor(desiredFaceSize: number = BLAZEFACE_FACE_SIZE) {
        this.method = {
            value: "YoloFace",
            version: 1,
        };
        this.desiredFaceSize = desiredFaceSize;
    }

    private async initOnnx() {
        console.log("start ort");
        this.onnxInferenceSession = await ort.InferenceSession.create(
            "/models/yoloface/yolov5s_face_640_640_dynamic.onnx",
        );
        const data = new Float32Array(1 * 3 * 640 * 640);
        const inputTensor = new ort.Tensor("float32", data, [1, 3, 640, 640]);
        // TODO(MR): onnx-yolo
        // const feeds: Record<string, ort.Tensor> = {};
        const feeds: Record<string, any> = {};
        const name = this.onnxInferenceSession.inputNames[0];
        feeds[name] = inputTensor;
        await this.onnxInferenceSession.run(feeds);
        console.log("start end");
    }

    private async getOnnxInferenceSession() {
        if (!this.onnxInferenceSession) {
            await this.initOnnx();
        }
        return this.onnxInferenceSession;
    }

    private preprocessImageBitmapToFloat32ChannelsFirst(
        imageBitmap: ImageBitmap,
        requiredWidth: number,
        requiredHeight: number,
        maintainAspectRatio: boolean = true,
        normFunction: (
            pixelValue: number,
        ) => number = normalizePixelBetween0And1,
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
            1 * 3 * requiredWidth * requiredHeight,
        );

        // Populate the Float32Array with normalized pixel values
        let pixelIndex = 0;
        const channelOffsetGreen = requiredHeight * requiredWidth;
        const channelOffsetBlue = 2 * requiredHeight * requiredWidth;
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
                processedImage[pixelIndex] = normFunction(pixel.r);
                processedImage[pixelIndex + channelOffsetGreen] = normFunction(
                    pixel.g,
                );
                processedImage[pixelIndex + channelOffsetBlue] = normFunction(
                    pixel.b,
                );
                pixelIndex++;
            }
        }

        return {
            data: processedImage,
            originalSize: {
                width: imageBitmap.width,
                height: imageBitmap.height,
            },
            newSize: { width: scaledWidth, height: scaledHeight },
        };
    }

    /**
     * @deprecated The method should not be used
     */
    private imageBitmapToTensorData(imageBitmap) {
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
        const data = new Float32Array(
            1 * 3 * imageBitmap.width * imageBitmap.height,
        );
        // Populate the Float32Array with normalized pixel values
        for (let i = 0; i < pixelData.length; i += 4) {
            // Normalize pixel values to the range [0, 1]
            data[i / 4] = pixelData[i] / 255.0; // Red channel
            data[i / 4 + imageBitmap.width * imageBitmap.height] =
                pixelData[i + 1] / 255.0; // Green channel
            data[i / 4 + 2 * imageBitmap.width * imageBitmap.height] =
                pixelData[i + 2] / 255.0; // Blue channel
        }

        return {
            data: data,
            shape: [1, 3, imageBitmap.width, imageBitmap.height],
        };
    }

    // The rowOutput is a Float32Array of shape [25200, 16], where each row represents a bounding box.
    private getFacesFromYoloOutput(
        rowOutput: Float32Array,
        minScore: number,
    ): Array<FaceDetection> {
        const faces: Array<FaceDetection> = [];
        // iterate over each row
        for (let i = 0; i < rowOutput.length; i += 16) {
            const score = rowOutput[i + 4];
            if (score < minScore) {
                continue;
            }
            // The first 4 values represent the bounding box's coordinates (x1, y1, x2, y2)
            const xCenter = rowOutput[i];
            const yCenter = rowOutput[i + 1];
            const width = rowOutput[i + 2];
            const height = rowOutput[i + 3];
            const xMin = xCenter - width / 2.0; // topLeft
            const yMin = yCenter - height / 2.0; // topLeft

            const leftEyeX = rowOutput[i + 5];
            const leftEyeY = rowOutput[i + 6];
            const rightEyeX = rowOutput[i + 7];
            const rightEyeY = rowOutput[i + 8];
            const noseX = rowOutput[i + 9];
            const noseY = rowOutput[i + 10];
            const leftMouthX = rowOutput[i + 11];
            const leftMouthY = rowOutput[i + 12];
            const rightMouthX = rowOutput[i + 13];
            const rightMouthY = rowOutput[i + 14];

            const box = new Box({
                x: xMin,
                y: yMin,
                width: width,
                height: height,
            });
            const probability = score as number;
            const landmarks = [
                new Point(leftEyeX, leftEyeY),
                new Point(rightEyeX, rightEyeY),
                new Point(noseX, noseY),
                new Point(leftMouthX, leftMouthY),
                new Point(rightMouthX, rightMouthY),
            ];
            const face: FaceDetection = {
                box,
                landmarks,
                probability,
                // detectionMethod: this.method,
            };
            faces.push(face);
        }
        return faces;
    }

    public getRelativeDetection(
        faceDetection: FaceDetection,
        dimensions: Dimensions,
    ): FaceDetection {
        const oldBox: Box = faceDetection.box;
        const box = new Box({
            x: oldBox.x / dimensions.width,
            y: oldBox.y / dimensions.height,
            width: oldBox.width / dimensions.width,
            height: oldBox.height / dimensions.height,
        });
        const oldLandmarks: Point[] = faceDetection.landmarks;
        const landmarks = oldLandmarks.map((l) => {
            return new Point(l.x / dimensions.width, l.y / dimensions.height);
        });
        return {
            box,
            landmarks,
            probability: faceDetection.probability,
        };
    }

    private async estimateOnnx(imageBitmap: ImageBitmap) {
        const maxFaceDistance = imageBitmap.width * MAX_FACE_DISTANCE_PERCENT;
        const preprocessResult =
            this.preprocessImageBitmapToFloat32ChannelsFirst(
                imageBitmap,
                640,
                640,
            );
        const data = preprocessResult.data;
        const resized = preprocessResult.newSize;
        const inputTensor = new ort.Tensor("float32", data, [1, 3, 640, 640]);
        // TODO(MR): onnx-yolo
        // const feeds: Record<string, ort.Tensor> = {};
        const feeds: Record<string, any> = {};
        feeds["input"] = inputTensor;
        const inferenceSession = await this.getOnnxInferenceSession();
        const runout = await inferenceSession.run(feeds);
        const outputData = runout.output.data;
        const faces = this.getFacesFromYoloOutput(
            outputData as Float32Array,
            0.7,
        );
        const inBox = newBox(0, 0, resized.width, resized.height);
        const toBox = newBox(0, 0, imageBitmap.width, imageBitmap.height);
        const transform = computeTransformToBox(inBox, toBox);
        const faceDetections: Array<FaceDetection> = faces?.map((f) => {
            const box = transformBox(f.box, transform);
            const normLandmarks = f.landmarks;
            const landmarks = transformPoints(normLandmarks, transform);
            return {
                box,
                landmarks,
                probability: f.probability as number,
            } as FaceDetection;
        });
        return removeDuplicateDetections(faceDetections, maxFaceDistance);
    }

    public async detectFaces(
        imageBitmap: ImageBitmap,
    ): Promise<Array<FaceDetection>> {
        // measure time taken
        const facesFromOnnx = await this.estimateOnnx(imageBitmap);
        return facesFromOnnx;
    }

    public async dispose() {
        const inferenceSession = await this.getOnnxInferenceSession();
        inferenceSession?.release();
        this.onnxInferenceSession = undefined;
    }
}

export default new YoloFaceDetectionService();
