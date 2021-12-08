import * as tf from '@tensorflow/tfjs-core';
import { gather } from '@tensorflow/tfjs';
import * as tflite from '@tensorflow/tfjs-tflite';
import {
    AlignedFace,
    FaceEmbedding,
    FaceEmbeddingService,
    FaceWithEmbedding,
} from 'types/machineLearning';
import { extractFaceImages } from 'utils/machineLearning/faceAlign';

class TFJSFaceEmbeddingService implements FaceEmbeddingService {
    private mobileFaceNetModel: tflite.TFLiteModel;
    private faceSize: number;

    public constructor(faceSize: number = 112) {
        this.faceSize = faceSize;
    }

    public async init() {
        tflite.setWasmPath('/js/tflite/');
        this.mobileFaceNetModel = await tflite.loadTFLiteModel(
            '/models/mobilefacenet/mobilefacenet.tflite'
        );

        console.log(
            'loaded mobileFaceNetModel: ',
            this.mobileFaceNetModel,
            await tf.getBackend()
        );
    }

    public getEmbedding(face: tf.Tensor4D) {
        return tf.tidy(() => {
            const normalizedFace = tf.sub(tf.div(face, 127.5), 1.0);
            return this.mobileFaceNetModel.predict(normalizedFace);
        });
    }

    public async getEmbeddingsBatch(
        faceImagesTensor
    ): Promise<Array<FaceEmbedding>> {
        const embeddings = [];
        for (let i = 0; i < faceImagesTensor.shape[0]; i++) {
            const embedding = tf.tidy(() => {
                const face = gather(faceImagesTensor, i).expandDims();
                const embedding = this.getEmbedding(face);
                return gather(embedding as any, 0);
            });
            embeddings[i] = embedding;
        }

        // TODO: return Float32Array instead of number[]
        return tf.stack(embeddings).array() as Promise<Array<FaceEmbedding>>;
    }

    public async getFaceEmbeddings(
        image: tf.Tensor3D,
        faces: Array<AlignedFace>
    ) {
        if (!faces || faces.length < 1) {
            return [];
        }

        const faceImagesTensor = extractFaceImages(image, faces, this.faceSize);
        const embeddings = await this.getEmbeddingsBatch(faceImagesTensor);
        tf.dispose(faceImagesTensor);
        // console.log('embeddings: ', embeddings[0]);

        const facesWithEmbeddings = new Array<FaceWithEmbedding>(faces.length);
        faces.forEach((face, index) => {
            facesWithEmbeddings[index] = {
                ...face,

                embedding: embeddings[index],
                embeddingMethod: {
                    value: 'MobileFaceNet',
                    version: 1,
                },
            };
        });

        return facesWithEmbeddings;
    }

    public async dispose() {}
}

export default TFJSFaceEmbeddingService;
