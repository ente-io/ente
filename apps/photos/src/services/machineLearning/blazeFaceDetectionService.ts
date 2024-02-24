import { addLogLine } from "@ente/shared/logging";
import { GraphModel } from "@tensorflow/tfjs-converter";
import * as tf from "@tensorflow/tfjs-core";
import {
    load as blazeFaceLoad,
    BlazeFaceModel,
    NormalizedFace,
} from "blazeface-back";
import {
    BLAZEFACE_FACE_SIZE,
    BLAZEFACE_INPUT_SIZE,
    BLAZEFACE_IOU_THRESHOLD,
    BLAZEFACE_MAX_FACES,
    BLAZEFACE_PASS1_SCORE_THRESHOLD,
    BLAZEFACE_SCORE_THRESHOLD,
    MAX_FACE_DISTANCE_PERCENT,
} from "constants/mlConfig";
import {
    FaceDetection,
    FaceDetectionMethod,
    FaceDetectionService,
    Versioned,
} from "types/machineLearning";
import { addPadding, crop, resizeToSquare } from "utils/image";
import { enlargeBox, newBox, normFaceBox } from "utils/machineLearning";
import {
    getNearestDetection,
    removeDuplicateDetections,
    transformPaddedToImage,
} from "utils/machineLearning/faceDetection";
import {
    computeTransformToBox,
    transformBox,
    transformPoints,
} from "utils/machineLearning/transform";
import { Box, Point } from "../../../thirdparty/face-api/classes";

class BlazeFaceDetectionService implements FaceDetectionService {
    private blazeFaceModel: Promise<BlazeFaceModel>;
    private blazeFaceBackModel: GraphModel;
    public method: Versioned<FaceDetectionMethod>;

    private desiredLeftEye = [0.36, 0.45];
    private desiredFaceSize;

    public constructor(desiredFaceSize: number = BLAZEFACE_FACE_SIZE) {
        this.method = {
            value: "BlazeFace",
            version: 1,
        };
        this.desiredFaceSize = desiredFaceSize;
    }

    private async init() {
        this.blazeFaceModel = blazeFaceLoad({
            maxFaces: BLAZEFACE_MAX_FACES,
            scoreThreshold: BLAZEFACE_PASS1_SCORE_THRESHOLD,
            iouThreshold: BLAZEFACE_IOU_THRESHOLD,
            modelUrl: "/models/blazeface/back/model.json",
            inputHeight: BLAZEFACE_INPUT_SIZE,
            inputWidth: BLAZEFACE_INPUT_SIZE,
        });
        addLogLine(
            "loaded blazeFaceModel: ",
            // await this.blazeFaceModel,
            // eslint-disable-next-line @typescript-eslint/await-thenable
            await tf.getBackend(),
        );
    }

    private getDlibAlignedFace(normFace: NormalizedFace): Box {
        const relX = 0.5;
        const relY = 0.43;
        const relScale = 0.45;

        const leftEyeCenter = normFace.landmarks[0];
        const rightEyeCenter = normFace.landmarks[1];
        const mountCenter = normFace.landmarks[3];

        const distToMouth = (pt) => {
            const dy = mountCenter[1] - pt[1];
            const dx = mountCenter[0] - pt[0];
            return Math.sqrt(dx * dx + dy * dy);
        };
        const eyeToMouthDist =
            (distToMouth(leftEyeCenter) + distToMouth(rightEyeCenter)) / 2;

        const size = Math.floor(eyeToMouthDist / relScale);

        const center = [
            (leftEyeCenter[0] + rightEyeCenter[0] + mountCenter[0]) / 3,
            (leftEyeCenter[1] + rightEyeCenter[1] + mountCenter[1]) / 3,
        ];

        const left = center[0] - relX * size;
        const top = center[1] - relY * size;
        const right = center[0] + relX * size;
        const bottom = center[1] + relY * size;

        return new Box({
            left: left,
            top: top,
            right: right,
            bottom: bottom,
        });
    }

    private getAlignedFace(normFace: NormalizedFace): Box {
        const leftEye = normFace.landmarks[0];
        const rightEye = normFace.landmarks[1];
        // const noseTip = normFace.landmarks[2];

        const dy = rightEye[1] - leftEye[1];
        const dx = rightEye[0] - leftEye[0];

        const desiredRightEyeX = 1.0 - this.desiredLeftEye[0];

        // const eyesCenterX = (leftEye[0] + rightEye[0]) / 2;
        // const yaw = Math.abs(noseTip[0] - eyesCenterX)
        const dist = Math.sqrt(dx * dx + dy * dy);
        let desiredDist = desiredRightEyeX - this.desiredLeftEye[0];
        desiredDist *= this.desiredFaceSize;
        const scale = desiredDist / dist;
        // addLogLine("scale: ", scale);

        const eyesCenter = [];
        eyesCenter[0] = Math.floor((leftEye[0] + rightEye[0]) / 2);
        eyesCenter[1] = Math.floor((leftEye[1] + rightEye[1]) / 2);
        // addLogLine("eyesCenter: ", eyesCenter);

        const faceWidth = this.desiredFaceSize / scale;
        const faceHeight = this.desiredFaceSize / scale;
        // addLogLine("faceWidth: ", faceWidth, "faceHeight: ", faceHeight)

        const tx = eyesCenter[0] - faceWidth * 0.5;
        const ty = eyesCenter[1] - faceHeight * this.desiredLeftEye[1];
        // addLogLine("tx: ", tx, "ty: ", ty);

        return new Box({
            left: tx,
            top: ty,
            right: tx + faceWidth,
            bottom: ty + faceHeight,
        });
    }

    public async detectFacesUsingModel(image: tf.Tensor3D) {
        const resizedImage = tf.image.resizeBilinear(image, [256, 256]);
        const reshapedImage = tf.reshape(resizedImage, [
            1,
            resizedImage.shape[0],
            resizedImage.shape[1],
            3,
        ]);
        const normalizedImage = tf.sub(tf.div(reshapedImage, 127.5), 1.0);
        // eslint-disable-next-line @typescript-eslint/await-thenable
        const results = await this.blazeFaceBackModel.predict(normalizedImage);
        // addLogLine('onFacesDetected: ', results);
        return results;
    }

    private async getBlazefaceModel() {
        if (!this.blazeFaceModel) {
            await this.init();
        }

        return this.blazeFaceModel;
    }

    private async estimateFaces(
        imageBitmap: ImageBitmap,
    ): Promise<Array<FaceDetection>> {
        const resized = resizeToSquare(imageBitmap, BLAZEFACE_INPUT_SIZE);
        const tfImage = tf.browser.fromPixels(resized.image);
        const blazeFaceModel = await this.getBlazefaceModel();
        // TODO: check if this works concurrently, else use serialqueue
        const faces = await blazeFaceModel.estimateFaces(tfImage);
        tf.dispose(tfImage);

        const inBox = newBox(0, 0, resized.width, resized.height);
        const toBox = newBox(0, 0, imageBitmap.width, imageBitmap.height);
        const transform = computeTransformToBox(inBox, toBox);
        // addLogLine("1st pass: ", { transform });

        const faceDetections: Array<FaceDetection> = faces?.map((f) => {
            const box = transformBox(normFaceBox(f), transform);
            const normLandmarks = (f.landmarks as number[][])?.map(
                (l) => new Point(l[0], l[1]),
            );
            const landmarks = transformPoints(normLandmarks, transform);
            return {
                box,
                landmarks,
                probability: f.probability as number,
                // detectionMethod: this.method,
            } as FaceDetection;
        });

        return faceDetections;
    }

    public async detectFaces(
        imageBitmap: ImageBitmap,
    ): Promise<Array<FaceDetection>> {
        const maxFaceDistance = imageBitmap.width * MAX_FACE_DISTANCE_PERCENT;
        const pass1Detections = await this.estimateFaces(imageBitmap);

        // run 2nd pass for accuracy
        const detections: Array<FaceDetection> = [];
        for (const pass1Detection of pass1Detections) {
            const imageBox = enlargeBox(pass1Detection.box, 2);
            const faceImage = crop(
                imageBitmap,
                imageBox,
                BLAZEFACE_INPUT_SIZE / 2,
            );
            const paddedImage = addPadding(faceImage, 0.5);
            const paddedBox = enlargeBox(imageBox, 2);
            const pass2Detections = await this.estimateFaces(paddedImage);

            pass2Detections?.forEach((d) =>
                transformPaddedToImage(d, faceImage, imageBox, paddedBox),
            );
            let selected = pass2Detections?.[0];
            if (pass2Detections?.length > 1) {
                // addLogLine('2nd pass >1 face', pass2Detections.length);
                selected = getNearestDetection(
                    pass1Detection,
                    pass2Detections,
                    // maxFaceDistance
                );
            }

            // we might miss 1st pass face actually having score within threshold
            // it is ok as results will be consistent with 2nd pass only detections
            if (selected && selected.probability >= BLAZEFACE_SCORE_THRESHOLD) {
                // addLogLine("pass2: ", { imageBox, paddedBox, transform, selected });
                detections.push(selected);
            }
        }

        return removeDuplicateDetections(detections, maxFaceDistance);
    }

    public async dispose() {
        const blazeFaceModel = await this.getBlazefaceModel();
        blazeFaceModel?.dispose();
        this.blazeFaceModel = undefined;
    }
}

export default new BlazeFaceDetectionService();
