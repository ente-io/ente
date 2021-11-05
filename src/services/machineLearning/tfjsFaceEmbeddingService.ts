import * as tf from '@tensorflow/tfjs';
import * as tflite from '@tensorflow/tfjs-tflite';
import {
    AlignedFace,
    FaceEmbedding,
    FaceImage,
} from 'utils/machineLearning/types';

class TFJSFaceEmbeddingService {
    private mobileFaceNetModel: tflite.TFLiteModel;

    public constructor() {}

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

    private async getEmbeddingsBatch(faceImagesTensor, boxes) {
        const embeddings = [];
        for (let i = 0; i < boxes.length; i++) {
            const face = tf.gather(faceImagesTensor, i).expandDims();
            const embedding = (await this.mobileFaceNetModel.predict(
                face
            )) as any;
            embeddings[i] = embedding.gather(0);
        }

        return tf.stack(embeddings);
    }

    public async getEmbeddings(image: tf.Tensor3D, faces: AlignedFace[]) {
        if (!faces || faces.length < 1) {
            return {
                embeddings: [],
                faceImages: [],
            };
        }

        const reshapedImage = tf.tidy(() => {
            if (!(image instanceof tf.Tensor)) {
                image = tf.browser.fromPixels(image);
            }
            return tf.expandDims(
                tf.cast(image as tf.Tensor, 'float32'),
                0
            ) as tf.Tensor4D;
        });

        const width = reshapedImage.shape[2];
        const height = reshapedImage.shape[1];
        console.log(
            'width: ',
            width,
            height,
            faces[0].topLeft,
            faces[0].bottomRight
        );
        const boxes = faces.map((face) => {
            return [
                face.alignedBox[1] / height,
                face.alignedBox[0] / width,
                face.alignedBox[3] / height,
                face.alignedBox[2] / width,
            ];
        });

        console.log('boxes: ', boxes[0]);

        const normalizedImage = tf.sub(
            tf.div(reshapedImage, 127.5),
            1.0
        ) as tf.Tensor4D;
        tf.dispose(reshapedImage);
        const faceImagesTensor = tf.image.cropAndResize(
            normalizedImage,
            boxes,
            tf.fill([boxes.length], 0, 'int32'),
            [112, 112]
        );
        tf.dispose(normalizedImage);
        // const embeddingsTensor = await this.mobileFaceNetModel.predict(faceImagesTensor);
        const embeddingsTensor = await this.getEmbeddingsBatch(
            faceImagesTensor,
            boxes
        );
        const embeddings = await embeddingsTensor.array();
        const faceImages = await faceImagesTensor.array();
        tf.dispose(faceImagesTensor);
        tf.dispose(embeddingsTensor);
        // console.log('embeddings: ', embeddings[0]);
        return {
            embeddings: embeddings as FaceEmbedding[],
            faceImages: faceImages as FaceImage[],
        };
    }
}

export default TFJSFaceEmbeddingService;
