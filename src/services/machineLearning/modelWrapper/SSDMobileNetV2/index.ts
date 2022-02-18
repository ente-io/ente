import * as tfconv from '@tensorflow/tfjs-converter';
import { SSDMobileNetV2Model } from './object';

export async function load() {
    const mobileNetV2 = await tfconv.loadGraphModel(
        '/models/OpenImagesSSDMobileNetV2/model.json'
    );

    const model = new SSDMobileNetV2Model(mobileNetV2);
    return model;
}

export { SSDMobileNetV2Model } from './object';
