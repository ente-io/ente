import * as tf from '@tensorflow/tfjs-core';
import { gather } from '@tensorflow/tfjs';
import { extractFaces } from 'utils/machineLearning';
import { AlignedFace, FaceEmbedding } from 'utils/machineLearning/types';
import { FaceRecognitionNet } from '../../../thirdparty/face-api/faceRecognitionNet';

class FAPIFaceEmbeddingService {
    private faceRecognitionNet: FaceRecognitionNet;
    private faceSize: number;

    public constructor(faceSize: number = 112) {
        this.faceRecognitionNet = new FaceRecognitionNet();
        this.faceSize = faceSize;
    }

    public async init() {
        await this.faceRecognitionNet.loadFromUri('/models/face-api/');

        console.log(
            'loaded faceRecognitionNet: ',
            this.faceRecognitionNet,
            await tf.getBackend()
        );
    }

    public async getEmbeddingsBatch(faceImagesTensor) {
        const embeddings = [];
        for (let i = 0; i < faceImagesTensor.shape[0]; i++) {
            const face = tf.tidy(() =>
                gather(faceImagesTensor, i).expandDims()
            );
            const embedding =
                await this.faceRecognitionNet.computeFaceDescriptor(face);
            tf.dispose(face);
            embeddings[i] = embedding;
        }

        return embeddings;
    }

    public async getEmbeddings(image: tf.Tensor3D, faces: AlignedFace[]) {
        if (!faces || faces.length < 1) {
            return {
                embeddings: [],
                faceImages: [],
            };
        }

        const boxes = faces.map((f) => f.alignedBox);
        const faceImagesTensor = extractFaces(image, boxes, this.faceSize);
        // const embeddingsTensor = await this.mobileFaceNetModel.predict(faceImagesTensor);
        const f32embeddings = await this.getEmbeddingsBatch(faceImagesTensor);
        const embeddings = f32embeddings;
        // const embeddings = await embeddingsTensor.array();
        // const faceImages = await faceImagesTensor.array();
        tf.dispose(faceImagesTensor);
        // tf.dispose(embeddingsTensor);
        // console.log('embeddings: ', embeddings[0]);
        return {
            embeddings: embeddings as FaceEmbedding[],
            // faceImages: faceImages as FaceImage[],
        };
    }

    public async dispose() {
        return this.faceRecognitionNet.dispose();
    }
}

export default FAPIFaceEmbeddingService;
