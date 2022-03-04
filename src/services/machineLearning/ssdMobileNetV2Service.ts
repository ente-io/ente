import * as tf from '@tensorflow/tfjs-core';
import {
    ObjectDetection,
    ObjectDetectionMethod,
    ObjectDetectionService,
    Versioned,
} from 'types/machineLearning';

import * as SSDMobileNet from '@tensorflow-models/coco-ssd';

class SSDMobileNetV2 implements ObjectDetectionService {
    private ssdMobileNetV2Model: SSDMobileNet.ObjectDetection;
    public method: Versioned<ObjectDetectionMethod>;

    public constructor() {
        this.method = {
            value: 'SSDMobileNetV2',
            version: 1,
        };
    }

    private async init() {
        this.ssdMobileNetV2Model = await SSDMobileNet.load({
            base: 'mobilenet_v2',
            modelUrl: '/models/ssdmobilenet/model.json',
        });
        console.log(
            'loaded ssdMobileNetV2Model',
            this.ssdMobileNetV2Model,
            tf.getBackend()
        );
    }

    public async detectObjects(image: ImageBitmap): Promise<ObjectDetection[]> {
        const results = await this.detectObjectUsingModel(image);

        return results;
    }

    private async getSSDMobileNetV2Model() {
        if (!this.ssdMobileNetV2Model) {
            await this.init();
        }

        return this.ssdMobileNetV2Model;
    }

    private disposeSSDMobileNetV2Model() {
        if (this.ssdMobileNetV2Model !== null) {
            this.ssdMobileNetV2Model = null;
        }
    }

    public async detectObjectUsingModel(imageBitmap: ImageBitmap) {
        const ssdMobileNetV2Model = await this.getSSDMobileNetV2Model();
        const tfImage = tf.browser.fromPixels(imageBitmap);
        const predictions = await ssdMobileNetV2Model.detect(tfImage);
        return predictions;
    }

    public async dispose() {
        const ssdMobileNetV2Model = await this.getSSDMobileNetV2Model();
        ssdMobileNetV2Model?.dispose();
        this.disposeSSDMobileNetV2Model();
    }
}

export default new SSDMobileNetV2();
