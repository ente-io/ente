import * as tfconv from '@tensorflow/tfjs-converter';
import { LoadOptions } from '@tensorflow/tfjs-core/dist/io/types';
import { SSDMobileNetV2Model } from './object';

const DEFAULT_MODEL_URL = '/models/OpenImagesSSDMobileNetV2/model.json';

export async function load(
    modelUrl: string = DEFAULT_MODEL_URL,
    options?: LoadOptions
) {
    const mobileNetV2 = await tfconv.loadGraphModel(modelUrl, options);

    const model = new SSDMobileNetV2Model(mobileNetV2);
    return model;
}

export { SSDMobileNetV2Model } from './object';
