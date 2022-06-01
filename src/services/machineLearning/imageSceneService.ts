import * as tf from '@tensorflow/tfjs-core';
import * as tfjsConverter from '@tensorflow/tfjs-converter';
import {
    ObjectDetection,
    SceneDetectionMethod,
    SceneDetectionService,
    Versioned,
} from 'types/machineLearning';
import sceneMap from 'utils/machineLearning/sceneMap';

class ImageScene implements SceneDetectionService {
    method: Versioned<SceneDetectionMethod>;
    model: tfjsConverter.GraphModel;

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

        const model = await tfjsConverter.loadGraphModel(
            '/models/imagescene/model.json'
        );
        console.log('loaded ImageScene model', model, tf.getBackend());
        this.model = model;
    }

    async detectScenes(image: ImageBitmap, minScore: number) {
        await tf.ready();

        if (!this.model) {
            await this.init();
        }

        const output = tf.tidy(() => {
            let tensor = tf.browser.fromPixels(image);

            tensor = tf.image.resizeBilinear(tensor, [224, 224]);
            tensor = tf.expandDims(tensor);
            tensor = tf.cast(tensor, 'float32');

            const output = this.model.predict(tensor);

            return output;
        });

        const data = await (output as tf.Tensor).data();
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
                    class: sceneMap.get(i),
                    score: outputData[i],
                    bbox: [0, 0, width, height],
                });
            }
        }
        return scenes;
    }
}

export default new ImageScene();
