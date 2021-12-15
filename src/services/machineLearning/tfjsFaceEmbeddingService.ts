import * as tf from '@tensorflow/tfjs-core';
import { gather } from '@tensorflow/tfjs';
import * as tflite from '@tensorflow/tfjs-tflite';
import {
    AlignedFace,
    FaceEmbedding,
    FaceEmbeddingMethod,
    FaceEmbeddingService,
    FaceWithEmbedding,
    Versioned,
} from 'types/machineLearning';
import { extractFaceImages } from 'utils/machineLearning/faceAlign';

class TFJSFaceEmbeddingService implements FaceEmbeddingService {
    private mobileFaceNetModel: Promise<tflite.TFLiteModel>;
    private faceSize: number;
    public method: Versioned<FaceEmbeddingMethod>;

    public constructor(faceSize: number = 112) {
        tflite.setWasmPath('/js/tflite/');
        this.method = {
            value: 'MobileFaceNet',
            version: 1,
        };
        this.faceSize = faceSize;
    }

    private async init() {
        this.mobileFaceNetModel = tflite.loadTFLiteModel(
            '/models/mobilefacenet/mobilefacenet.tflite'
        );

        console.log(
            'loaded mobileFaceNetModel: ',
            await this.mobileFaceNetModel,
            await tf.getBackend()
        );
    }

    private async getMobileFaceNetModel() {
        if (!this.mobileFaceNetModel) {
            await this.init();
        }

        return this.mobileFaceNetModel;
    }

    public getEmbedding(
        face: tf.Tensor4D,
        mobileFaceNetModel: tflite.TFLiteModel
    ) {
        return tf.tidy(() => {
            const normalizedFace = tf.sub(tf.div(face, 127.5), 1.0);
            return mobileFaceNetModel.predict(normalizedFace);
        });
    }

    public async getEmbeddingsBatch(
        faceImagesTensor
    ): Promise<Array<FaceEmbedding>> {
        const mobileFaceNetModel = await this.getMobileFaceNetModel();

        const embeddingsTensor = tf.tidy(() => {
            const embeddings = [];
            for (let i = 0; i < faceImagesTensor.shape[0]; i++) {
                const face = gather(faceImagesTensor, i).expandDims();
                const embedding = this.getEmbedding(face, mobileFaceNetModel);
                embeddings[i] = gather(embedding as any, 0);
            }
            return tf.stack(embeddings);
        });

        // TODO: return Float32Array instead of number[]
        const faceEmbeddings =
            (await embeddingsTensor.array()) as Array<FaceEmbedding>;
        tf.dispose(embeddingsTensor);
        return faceEmbeddings;
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
                // embeddingMethod: this.method,
            };
        });

        return facesWithEmbeddings;
    }

    public async dispose() {
        this.mobileFaceNetModel = undefined;
    }
}

export default new TFJSFaceEmbeddingService();
