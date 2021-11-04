import {
    load as blazeFaceLoad,
    BlazeFaceModel,
} from '@tensorflow-models/blazeface';
import * as tf from '@tensorflow/tfjs';
import { AlignedFace } from 'utils/machineLearning/types';

class TFJSFaceDetectionService {
    private blazeFaceModel: BlazeFaceModel;
    private blazeFaceBackModel: tf.GraphModel;

    private desiredLeftEye = [0.3, 0.4];
    private desiredFaceWidth = 112;
    private desiredFaceHeight = 112;
    private minFacePixels = 50;

    public constructor() {}

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

    private getAlignedFace(normFace): AlignedFace {
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
        desiredDist *= this.desiredFaceWidth;
        const scale = desiredDist / dist;
        // console.log("scale: ", scale);

        const eyesCenter = [];
        eyesCenter[0] = Math.floor((leftEye[0] + rightEye[0]) / 2);
        eyesCenter[1] = Math.floor((leftEye[1] + rightEye[1]) / 2);
        // console.log("eyesCenter: ", eyesCenter);

        const faceWidth = this.desiredFaceWidth / scale;
        const faceHeight = this.desiredFaceHeight / scale;
        // console.log("faceWidth: ", faceWidth, "faceHeight: ", faceHeight)

        const tx = eyesCenter[0] - faceWidth * 0.5;
        const ty = eyesCenter[1] - faceHeight * this.desiredLeftEye[1];
        // console.log("tx: ", tx, "ty: ", ty);

        return {
            ...normFace,
            alignedBox: [tx, ty, tx + faceWidth, ty + faceHeight],
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
        const normalizedFaces = await this.blazeFaceModel.estimateFaces(
            image as any
        );
        const alignedFaces = normalizedFaces.map((normFace) =>
            this.getAlignedFace(normFace)
        );
        const filtertedFaces = alignedFaces.filter((face) => {
            return (
                face.alignedBox[2] - face.alignedBox[0] > this.minFacePixels &&
                face.alignedBox[3] - face.alignedBox[1] > this.minFacePixels
            );
        });
        return filtertedFaces;
    }
}

export default TFJSFaceDetectionService;
