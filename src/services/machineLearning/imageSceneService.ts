import * as tf from '@tensorflow/tfjs-core';
import * as tfjsConverter from '@tensorflow/tfjs-converter';
import {
    ObjectDetection,
    SceneDetectionMethod,
    SceneDetectionService,
    Versioned,
} from 'types/machineLearning';
import { SCENE_DETECTION_IMAGE_SIZE } from 'constants/machineLearning/config';
import { resizeToSquare } from 'utils/image';

class ImageScene implements SceneDetectionService {
    method: Versioned<SceneDetectionMethod>;
    private model: tfjsConverter.GraphModel;
    private sceneMap: { [key: string]: string };
    private ready: Promise<void>;

    public constructor() {
        this.method = {
            value: 'ImageScene',
            version: 1,
        };
    }

    private async init() {
        if (this.model) {
            return;
        }

        this.sceneMap = await (
            await fetch('/models/imagescene/sceneMap.json')
        ).json();

        const model = await tfjsConverter.loadGraphModel(
            '/models/imagescene/model.json'
        );
        console.log('loaded ImageScene model', tf.getBackend());
        this.model = model;

        // warmup the model
        const warmupResult = this.model.predict(
            tf.zeros([1, 224, 224, 3])
        ) as tf.Tensor;
        await warmupResult.data();
        warmupResult.dispose();
    }

    private async getImageSceneModel() {
        if (!this.ready) {
            this.ready = this.init();
        }
        await this.ready;
        return this.model;
    }

    async detectScenes(image: ImageBitmap, minScore: number) {
        await tf.ready();
        // scene detection model takes fixed-shaped (224x224) inputs
        // https://tfhub.dev/sayannath/lite-model/image-scene/1
        const resized = resizeToSquare(image, SCENE_DETECTION_IMAGE_SIZE);

        const model = await this.getImageSceneModel();

        const output = tf.tidy(() => {
            const tfImage = tf.browser.fromPixels(resized.image);
            const input = tf.expandDims(tf.cast(tfImage, 'float32'));
            const output = model.predict(input) as tf.Tensor;
            return output;
        });

        const data = await output.data();
        output.dispose();

        const scenes = this.getScenes(
            data as Float32Array,
            image.width,
            image.height,
            minScore
        );

        return scenes;
    }

    private getScenes(
        outputData: Float32Array,
        width: number,
        height: number,
        minScore: number
    ): ObjectDetection[] {
        const scenes = [];
        for (let i = 0; i < outputData.length; i++) {
            if (outputData[i] >= minScore) {
                scenes.push({
                    class: this.sceneMap[i.toString()],
                    score: outputData[i],
                    bbox: [0, 0, width, height],
                });
            }
        }
        return scenes;
    }
}

export default new ImageScene();
