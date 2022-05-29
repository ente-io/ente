import * as tf from '@tensorflow/tfjs';
import '@tensorflow/tfjs-backend-webgl';
import '@tensorflow/tfjs-backend-cpu';
import sceneMap from 'utils/machineLearning/sceneMap';

const MIN_SCENE_DETECTION_SCORE = 0.25;

class SceneDetectionService {
    model: tf.GraphModel;

    async init() {
        if (this.model) {
            return;
        }

        const model = await tf.loadGraphModel('/models/imagescene/model.json');
        console.log('loaded image-scene model', model, tf.getBackend());
        this.model = model;
    }

    async run(file: File) {
        const bmp = await createImageBitmap(file);
        tf.ready().then(async () => {
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
            const scenes = this.getScenes(data as Float32Array);
            console.log('scenes', scenes);
        });
    }

    getScenes(outputData: Float32Array) {
        const scenes = [];
        for (let i = 0; i < outputData.length; i++) {
            if (outputData[i] >= MIN_SCENE_DETECTION_SCORE) {
                scenes.push({
                    name: sceneMap.get(i),
                    score: outputData[i],
                });
            }
        }
        return scenes;
    }
}

export default new SceneDetectionService();
