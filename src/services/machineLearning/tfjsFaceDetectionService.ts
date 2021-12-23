import {
    load as blazeFaceLoad,
    BlazeFaceModel,
    NormalizedFace,
} from '@tensorflow-models/blazeface';
import * as tf from '@tensorflow/tfjs-core';
import { GraphModel } from '@tensorflow/tfjs';
import {
    BLAZEFACE_FACE_SIZE,
    BLAZEFACE_INPUT_SIZE,
    BLAZEFACE_IOU_THRESHOLD,
    BLAZEFACE_MAX_FACES,
    BLAZEFACE_SCORE_THRESHOLD,
    DetectedFace,
    FaceDetectionMethod,
    FaceDetectionService,
    Versioned,
} from 'types/machineLearning';
import { Box, Point } from '../../../thirdparty/face-api/classes';
import { resizeToSquare } from 'utils/image';

class TFJSFaceDetectionService implements FaceDetectionService {
    private blazeFaceModel: Promise<BlazeFaceModel>;
    private blazeFaceBackModel: GraphModel;
    public method: Versioned<FaceDetectionMethod>;

    private desiredLeftEye = [0.36, 0.45];
    private desiredFaceSize;

    public constructor(desiredFaceSize: number = BLAZEFACE_FACE_SIZE) {
        this.method = {
            value: 'BlazeFace',
            version: 1,
        };
        this.desiredFaceSize = desiredFaceSize;
    }

    private async init() {
        this.blazeFaceModel = blazeFaceLoad({
            maxFaces: BLAZEFACE_MAX_FACES,
            scoreThreshold: BLAZEFACE_SCORE_THRESHOLD,
            iouThreshold: BLAZEFACE_IOU_THRESHOLD,
            modelUrl: '/models/blazeface/back/model.json',
            inputHeight: BLAZEFACE_INPUT_SIZE,
            inputWidth: BLAZEFACE_INPUT_SIZE,
        });
        console.log(
            'loaded blazeFaceModel: ',
            // await this.blazeFaceModel,
            await tf.getBackend()
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
        // console.log("scale: ", scale);

        const eyesCenter = [];
        eyesCenter[0] = Math.floor((leftEye[0] + rightEye[0]) / 2);
        eyesCenter[1] = Math.floor((leftEye[1] + rightEye[1]) / 2);
        // console.log("eyesCenter: ", eyesCenter);

        const faceWidth = this.desiredFaceSize / scale;
        const faceHeight = this.desiredFaceSize / scale;
        // console.log("faceWidth: ", faceWidth, "faceHeight: ", faceHeight)

        const tx = eyesCenter[0] - faceWidth * 0.5;
        const ty = eyesCenter[1] - faceHeight * this.desiredLeftEye[1];
        // console.log("tx: ", tx, "ty: ", ty);

        return new Box({
            left: tx,
            top: ty,
            right: tx + faceWidth,
            bottom: ty + faceHeight,
        });
    }

    public async detectFacesUsingModel(image: tf.Tensor3D) {
        const resizedImage = tf.image.resizeBilinear(image, [256, 256]);
        const reshapedImage = resizedImage.reshape([
            1,
            resizedImage.shape[0],
            resizedImage.shape[1],
            3,
        ]);
        const normalizedImage = tf.sub(tf.div(reshapedImage, 127.5), 1.0);
        const results = await this.blazeFaceBackModel.predict(normalizedImage);
        // console.log('onFacesDetected: ', results);
        return results;
    }

    private async getBlazefaceModel() {
        if (!this.blazeFaceModel) {
            await this.init();
        }

        return this.blazeFaceModel;
    }

    public async detectFaces(
        imageBitmap: ImageBitmap
    ): Promise<Array<DetectedFace>> {
        const resized = resizeToSquare(imageBitmap, BLAZEFACE_INPUT_SIZE);
        const widthRatio = imageBitmap.width / resized.width;
        const heightRatio = imageBitmap.height / resized.height;
        const tfImage = tf.browser.fromPixels(resized.image);
        const blazeFaceModel = await this.getBlazefaceModel();
        const faces = await blazeFaceModel.estimateFaces(tfImage);
        tf.dispose(tfImage);

        const detectedFaces: Array<DetectedFace> = faces?.map(
            (normalizedFace) => {
                const landmarks = normalizedFace.landmarks as number[][];
                return {
                    box: new Box({
                        left: normalizedFace.topLeft[0] * widthRatio,
                        top: normalizedFace.topLeft[1] * heightRatio,
                        right: normalizedFace.bottomRight[0] * widthRatio,
                        bottom: normalizedFace.bottomRight[1] * heightRatio,
                    }),
                    landmarks:
                        landmarks &&
                        landmarks.map(
                            (l) =>
                                new Point(l[0] * widthRatio, l[1] * heightRatio)
                        ),
                    probability: normalizedFace.probability as number,
                    // detectionMethod: this.method,
                } as DetectedFace;
            }
        );

        return detectedFaces;
    }

    public async dispose() {
        const blazeFaceModel = await this.getBlazefaceModel();
        blazeFaceModel?.dispose();
        this.blazeFaceModel = undefined;
    }
}

export default new TFJSFaceDetectionService();
