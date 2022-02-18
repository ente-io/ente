import * as tfconv from '@tensorflow/tfjs-converter';
import * as tf from '@tensorflow/tfjs-core';

export class SSDMobileNetV2Model {
    private ssdMobileNetV2Model: tfconv.GraphModel;

    constructor(model: tfconv.GraphModel) {
        this.ssdMobileNetV2Model = model;
    }
    dispose(): void {
        if (this.ssdMobileNetV2Model !== null) {
            this.ssdMobileNetV2Model.dispose();
        }
    }

    async getObjectClasses(inputImage: tf.Tensor4D) {
        const prediction = this.ssdMobileNetV2Model.predict(inputImage);

        return prediction;
    }
}
