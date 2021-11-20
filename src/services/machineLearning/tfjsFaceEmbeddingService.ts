import * as tf from '@tensorflow/tfjs-core';
import { gather } from '@tensorflow/tfjs';
import * as tflite from '@tensorflow/tfjs-tflite';
import { AlignedFace, FaceEmbedding } from 'utils/machineLearning/types';
import { extractFaces } from 'utils/machineLearning';

class TFJSFaceEmbeddingService {
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

        return tf.stack(embeddings).array() as Promise<Array<FaceEmbedding>>;
    }

    public async getEmbeddings(image: tf.Tensor3D, faces: AlignedFace[]) {
        if (!faces || faces.length < 1) {
            return {
                embeddings: [],
                faceImages: [],
            };
        }

        const faceImagesTensor = tf.tidy(() => {
            return extractFaces(
                image,
                faces.map((f) => f.alignedBox),
                this.faceSize
            );
        });
        const embeddings = await this.getEmbeddingsBatch(faceImagesTensor);
        // const embeddings = await embeddingsTensor.array();
        // const faceImages = await faceImagesTensor.array();
        tf.dispose(faceImagesTensor);
        // tf.dispose(embeddingsTensor);
        // console.log('embeddings: ', embeddings[0]);
        return {
            embeddings: embeddings,
            // faceImages: faceImages as FaceImage[],
        };
    }

    public dispose() {}
}

export default TFJSFaceEmbeddingService;
