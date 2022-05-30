import * as tf from '@tensorflow/tfjs';
import {
    ObjectDetection,
    SceneDetectionMethod,
    SceneDetectionService,
    Versioned,
} from 'types/machineLearning';
import sceneMap from 'utils/machineLearning/sceneMap';

const MIN_SCENE_DETECTION_SCORE = 0.1;

class ImageScene implements SceneDetectionService {
    method: Versioned<SceneDetectionMethod>;
    model: tf.GraphModel;

    public constructor() {
        this.method = {
            value: 'Image-Scene',
            version: 1,
        };
    }

    private async init() {
        if (this.model) {
            return;
        }

        const model = await tf.loadGraphModel('/models/imagescene/model.json');
        console.log('loaded image-scene model', model, tf.getBackend());
        this.model = model;
    }

    async detectByFile(file: File) {
        const bmp = await createImageBitmap(file);

        await tf.ready();

        if (!this.model) {
            await this.init();
        }

        const currTime = new Date().getTime();
        const output = tf.tidy(() => {
            let tensor = tf.browser.fromPixels(bmp);

            tensor = tf.image.resizeBilinear(tensor, [224, 224]);
            tensor = tf.expandDims(tensor);
            tensor = tf.cast(tensor, 'float32');

            const output = this.model.predict(tensor, {
                verbose: true,
            });

            return output;
        });

        console.log('done in', new Date().getTime() - currTime, 'ms');

        const data = await (output as tf.Tensor).data();
        const scenes = this.getScenes(
            data as Float32Array,
            bmp.width,
            bmp.height
        );
        console.log(`scenes for ${file.name}`, scenes);
    }

    async detectScenes(image: ImageBitmap) {
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
            image.height
        );

        return scenes;
    }

    private getScenes(
        outputData: Float32Array,
        width: number,
        height: number
    ): ObjectDetection[] {
        const scenes = [];
        for (let i = 0; i < outputData.length; i++) {
            if (outputData[i] >= MIN_SCENE_DETECTION_SCORE) {
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
