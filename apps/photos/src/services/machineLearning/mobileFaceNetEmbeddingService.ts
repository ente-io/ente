import * as tf from '@tensorflow/tfjs-core';
import { TFLiteModel } from '@tensorflow/tfjs-tflite';
import { MOBILEFACENET_FACE_SIZE } from 'constants/mlConfig';
import PQueue from 'p-queue';
import {
    FaceEmbedding,
    FaceEmbeddingMethod,
    FaceEmbeddingService,
    Versioned,
} from 'types/machineLearning';
import { addLogLine } from '@ente/shared/logging';
import { imageBitmapsToTensor4D } from 'utils/machineLearning';

class MobileFaceNetEmbeddingService implements FaceEmbeddingService {
    public method: Versioned<FaceEmbeddingMethod>;
    public faceSize: number;

    private mobileFaceNetModel: Promise<TFLiteModel>;
    private serialQueue: PQueue;

    public constructor(faceSize: number = MOBILEFACENET_FACE_SIZE) {
        this.method = {
            value: 'MobileFaceNet',
            version: 2,
        };
        this.faceSize = faceSize;
        // TODO: set timeout
        this.serialQueue = new PQueue({ concurrency: 1 });
    }

    private async init() {
        // TODO: can also create new instance per new syncContext
        const tflite = await import('@tensorflow/tfjs-tflite');
        tflite.setWasmPath('/js/tflite/');

        this.mobileFaceNetModel = tflite.loadTFLiteModel(
            '/models/mobilefacenet/mobilefacenet.tflite'
        );

        addLogLine('loaded mobileFaceNetModel: ', tf.getBackend());
    }

    private async getMobileFaceNetModel() {
        if (!this.mobileFaceNetModel) {
            await this.init();
        }

        return this.mobileFaceNetModel;
    }

    public getFaceEmbeddingTF(
        faceTensor: tf.Tensor4D,
        mobileFaceNetModel: TFLiteModel
    ): tf.Tensor2D {
        return tf.tidy(() => {
            const normalizedFace = tf.sub(tf.div(faceTensor, 127.5), 1.0);
            return mobileFaceNetModel.predict(normalizedFace) as tf.Tensor2D;
        });
    }

    // Do not use this, use getFaceEmbedding which calls this through serialqueue
    private async getFaceEmbeddingNoQueue(
        faceImage: ImageBitmap
    ): Promise<FaceEmbedding> {
        const mobileFaceNetModel = await this.getMobileFaceNetModel();

        const embeddingTensor = tf.tidy(() => {
            const faceTensor = imageBitmapsToTensor4D([faceImage]);
            const embeddingsTensor = this.getFaceEmbeddingTF(
                faceTensor,
                mobileFaceNetModel
            );
            return tf.squeeze(embeddingsTensor, [0]);
        });

        const embedding = new Float32Array(await embeddingTensor.data());
        embeddingTensor.dispose();

        return embedding;
    }

    // TODO: TFLiteModel seems to not work concurrenly,
    // remove serialqueue if that is not the case
    private async getFaceEmbedding(
        faceImage: ImageBitmap
    ): Promise<FaceEmbedding> {
        return this.serialQueue.add(() =>
            this.getFaceEmbeddingNoQueue(faceImage)
        );
    }

    public async getFaceEmbeddings(
        faceImages: Array<ImageBitmap>
    ): Promise<Array<FaceEmbedding>> {
        return Promise.all(
            faceImages.map((faceImage) => this.getFaceEmbedding(faceImage))
        );
    }

    public async dispose() {
        this.mobileFaceNetModel = undefined;
    }
}

export default new MobileFaceNetEmbeddingService();
