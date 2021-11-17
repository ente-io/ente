import * as tf from '@tensorflow/tfjs-core';

import { NetInput, TNetInput, toNetInput } from '../dom';
import { NeuralNetwork } from '../NeuralNetwork';
import { normalize } from '../ops';
import { denseBlock3 } from './denseBlock';
import { extractParamsFromWeigthMapTiny } from './extractParamsFromWeigthMapTiny';
import { extractParamsTiny } from './extractParamsTiny';
import { IFaceFeatureExtractor, TinyFaceFeatureExtractorParams } from './types';

export class TinyFaceFeatureExtractor extends NeuralNetwork<TinyFaceFeatureExtractorParams> implements IFaceFeatureExtractor<TinyFaceFeatureExtractorParams> {

  constructor() {
    super('TinyFaceFeatureExtractor')
  }

  public forwardInput(input: NetInput): tf.Tensor4D {

    const { params } = this

    if (!params) {
      throw new Error('TinyFaceFeatureExtractor - load model before inference')
    }

    return tf.tidy(() => {
      const batchTensor = input.toBatchTensor(112, true)
      const meanRgb = [122.782, 117.001, 104.298]
      const normalized = normalize(batchTensor, meanRgb).div(tf.scalar(255)) as tf.Tensor4D

      let out = denseBlock3(normalized, params.dense0, true)
      out = denseBlock3(out, params.dense1)
      out = denseBlock3(out, params.dense2)
      out = tf.avgPool(out, [14, 14], [2, 2], 'valid')

      return out
    })
  }

  public async forward(input: TNetInput): Promise<tf.Tensor4D> {
    return this.forwardInput(await toNetInput(input))
  }

  protected getDefaultModelName(): string {
    return 'face_feature_extractor_tiny_model'
  }

  protected extractParamsFromWeigthMap(weightMap: tf.NamedTensorMap) {
    return extractParamsFromWeigthMapTiny(weightMap)
  }

  protected extractParams(weights: Float32Array) {
    return extractParamsTiny(weights)
  }
}