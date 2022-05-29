import * as tf from '@tensorflow/tfjs-core';
import '@tensorflow/tfjs-backend-webgl';
import { TFLiteModel } from '@tensorflow/tfjs-tflite';

class SceneDetectionService {
    model: Promise<TFLiteModel>;
    async init() {
        if (this.model) {
            return this.model;
        }

        const tflite = await import('@tensorflow/tfjs-tflite');
        tflite.setWasmPath('/js/tflite/');

        this.model = tflite.loadTFLiteModel(
            '/models/imagescene/lite-model_image-scene_1.tflite'
        );

        await tf.ready();
        console.log(
            'loaded image-scene model: ',
            await this.model,
            tf.getBackend()
        );

        return this.model;
    }

    async run(file: File, model: TFLiteModel) {
        const bmp = await createImageBitmap(file);
        tf.ready().then(async () => {
            const currTime = new Date().getTime();
            const output = tf.tidy(() => {
                let tensor = tf.browser.fromPixels(bmp);
                console.log(tensor.shape);
                tensor = tf.image.resizeBilinear(tensor, [224, 224]);
                tensor = tf.expandDims(tensor);
                tensor = tf.cast(tensor, 'float32');
                console.log('starting', tensor);
                const output = model.predict(tensor, {
                    verbose: true,
                });
                return output;
            });
            console.log({ output });
            console.log('done in', new Date().getTime() - currTime, 'ms');
        });
    }
}

export default new SceneDetectionService();
