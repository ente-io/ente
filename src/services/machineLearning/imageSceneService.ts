import * as tf from '@tensorflow/tfjs-core';
import * as tfjsConverter from '@tensorflow/tfjs-converter';
import {
    ObjectDetection,
    SceneDetectionMethod,
    SceneDetectionService,
    Versioned,
} from 'types/machineLearning';

class ImageScene implements SceneDetectionService {
    method: Versioned<SceneDetectionMethod>;
    model: tfjsConverter.GraphModel;
    sceneMap: { [key: string]: string };

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
        console.log('loaded ImageScene model', model, tf.getBackend());
        this.model = model;

        // warmup the model
        const warmupResult = this.model.predict(tf.zeros([1, 224, 224, 3]));
        await (warmupResult as tf.Tensor).data();
        (warmupResult as tf.Tensor).dispose();
    }

    async detectScenes(image: ImageBitmap, minScore: number) {
        await tf.ready();

        if (!this.model) {
            await this.init();
        }

        const output = tf.tidy(() => {
            const tensor = tf.browser.fromPixels(image);

            // This model takes fixed-shaped (224x224) inputs
            // https://tfhub.dev/sayannath/lite-model/image-scene/1
            let resizedTensor = tf.image.resizeBilinear(tensor, [224, 224]);

            resizedTensor = tf.expandDims(resizedTensor);
            resizedTensor = tf.cast(resizedTensor, 'float32');

            const output = this.model.predict(resizedTensor);

            return output;
        });

        const data = await (output as tf.Tensor).data();
        (output as tf.Tensor).dispose();

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
