import { gather } from '@tensorflow/tfjs';
import * as tf from '@tensorflow/tfjs-core';
import * as tflite from '@tensorflow/tfjs-tflite';
import {
    AlignedFace,
    FaceEmbedding,
    FaceEmbeddingMethod,
    FaceEmbeddingService,
    Versioned,
} from 'types/machineLearning';
import { imageBitmapsToTensor4D } from 'utils/machineLearning';
import { ibExtractFaceImages } from 'utils/machineLearning/faceAlign';
import { ibExtractFaceImagesFromCrops } from 'utils/machineLearning/faceCrop';

class TFJSFaceEmbeddingService implements FaceEmbeddingService {
    private mobileFaceNetModel: Promise<tflite.TFLiteModel>;
    private faceSize: number;
    public method: Versioned<FaceEmbeddingMethod>;

    public constructor(faceSize: number = 112) {
        tflite.setWasmPath('/js/tflite/');
        this.method = {
            value: 'MobileFaceNet',
            version: 2,
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
        image: ImageBitmap,
        faces: Array<AlignedFace>
    ) {
        if (!faces || faces.length < 1) {
            return [];
        }

        let faceImages: Array<ImageBitmap>;
        if (faces.length === faces.filter((f) => f.crop).length) {
            faceImages = await ibExtractFaceImagesFromCrops(
                faces,
                this.faceSize
            );
        } else {
            const faceAlignments = faces.map((f) => f.alignment);
            faceImages = await ibExtractFaceImages(
                image,
                faceAlignments,
                this.faceSize
            );
        }

        const faceImagesTensor = imageBitmapsToTensor4D(faceImages);
        faceImages.forEach((f) => f.close());
        const embeddings = await this.getEmbeddingsBatch(faceImagesTensor);
        tf.dispose(faceImagesTensor);
        // console.log('embeddings: ', embeddings[0]);

        return embeddings;
    }

    public async dispose() {
        this.mobileFaceNetModel = undefined;
    }
}

export default new TFJSFaceEmbeddingService();
