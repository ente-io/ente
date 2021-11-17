import * as tf from '@tensorflow/tfjs-core';
import { gather } from '@tensorflow/tfjs';
import { extractFaces } from 'utils/machineLearning';
import { AlignedFace } from 'utils/machineLearning/types';
import { FaceLandmarks68 } from '../../../thirdparty/face-api/classes';
import { FaceLandmark68Net } from '../../../thirdparty/face-api/faceLandmarkNet';

class FAPIFaceLandmarksService {
    private faceLandmarkNet: FaceLandmark68Net;
    private faceSize;

    public constructor(faceSize: number = 112) {
        this.faceLandmarkNet = new FaceLandmark68Net();
        this.faceSize = faceSize;
    }

    public async init() {
        await this.faceLandmarkNet.loadFromUri('/models/face-api/');

        console.log(
            'loaded faceLandmarkNet: ',
            this.faceLandmarkNet,
            await tf.getBackend()
        );
    }

    private async getLandmarksBatch(faceImagesTensor) {
        const landmarks = [];
        for (let i = 0; i < faceImagesTensor.shape[0]; i++) {
            const face = tf.tidy(() =>
                gather(faceImagesTensor, i).expandDims()
            );
            const landmark = await this.faceLandmarkNet.detectLandmarks(face);
            tf.dispose(face);
            landmarks[i] = landmark;
        }

        return landmarks;
    }

    public async detectLandmarks(image: tf.Tensor3D, faces: AlignedFace[]) {
        if (!faces || faces.length < 1) {
            return [] as Array<FaceLandmarks68>;
        }

        const boxes = faces.map((f) => f.alignedBox);
        const faceImagesTensor = extractFaces(image, boxes, this.faceSize);

        const landmarks = await this.getLandmarksBatch(faceImagesTensor);

        tf.dispose(faceImagesTensor);

        return landmarks as Array<FaceLandmarks68>;
    }

    public async dispose() {
        return this.faceLandmarkNet.dispose();
    }
}

export default FAPIFaceLandmarksService;
