import {
    load as blazeFaceLoad,
    BlazeFaceModel,
    NormalizedFace,
} from '@tensorflow-models/blazeface';
import * as tf from '@tensorflow/tfjs-core';
import { GraphModel } from '@tensorflow/tfjs';
import { AlignedFace } from 'utils/machineLearning/types';
import { Box } from '../../../thirdparty/face-api/classes';

class TFJSFaceDetectionService {
    private blazeFaceModel: BlazeFaceModel;
    private blazeFaceBackModel: GraphModel;

    private desiredLeftEye = [0.36, 0.45];
    private desiredFaceSize;
    // private desiredFaceHeight = 112;

    public constructor(desiredFaceSize: number = 112) {
        this.desiredFaceSize = desiredFaceSize;
    }

    public async init() {
        this.blazeFaceModel = await blazeFaceLoad({
            maxFaces: 10,
            scoreThreshold: 0.5,
            iouThreshold: 0.3,
            modelUrl: '/models/blazeface/back/model.json',
            inputHeight: 256,
            inputWidth: 256,
        });
        console.log(
            'loaded blazeFaceModel: ',
            this.blazeFaceModel,
            await tf.getBackend()
        );
    }

    private getDlibAlignedFace(normFace: NormalizedFace): AlignedFace {
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

        return {
            ...normFace,
            alignedBox: new Box({
                left: left,
                top: top,
                right: right,
                bottom: bottom,
            }),
        };
    }

    private getAlignedFace(normFace: NormalizedFace): AlignedFace {
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

        return {
            ...normFace,
            alignedBox: new Box({
                left: tx,
                top: ty,
                right: tx + faceWidth,
                bottom: ty + faceHeight,
            }),
        };
    }

    public async detectFaces(image: tf.Tensor3D) {
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

    public async estimateFaces(image: tf.Tensor3D) {
        const normalizedFaces = await this.blazeFaceModel.estimateFaces(image);
        const alignedFaces = normalizedFaces.map((normFace) =>
            this.getAlignedFace(normFace)
        );

        return alignedFaces;
    }

    public async dispose() {
        this.blazeFaceModel.dispose();
    }
}

export default TFJSFaceDetectionService;
