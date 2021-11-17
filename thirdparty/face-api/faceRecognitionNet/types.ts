import * as tf from '@tensorflow/tfjs-core';

import { ConvParams } from '../common';

export type ScaleLayerParams = {
  weights: tf.Tensor1D
  biases: tf.Tensor1D
}
export type ResidualLayerParams = {
  conv1: ConvLayerParams
  conv2: ConvLayerParams
}

export type ConvLayerParams = {
  conv: ConvParams
  scale: ScaleLayerParams
}

export type NetParams = {
  conv32_down: ConvLayerParams
  conv32_1: ResidualLayerParams
  conv32_2: ResidualLayerParams
  conv32_3: ResidualLayerParams
  conv64_down: ResidualLayerParams
  conv64_1: ResidualLayerParams
  conv64_2: ResidualLayerParams
  conv64_3: ResidualLayerParams
  conv128_down: ResidualLayerParams
  conv128_1: ResidualLayerParams
  conv128_2: ResidualLayerParams
  conv256_down: ResidualLayerParams
  conv256_1: ResidualLayerParams
  conv256_2: ResidualLayerParams
  conv256_down_out: ResidualLayerParams
  fc: tf.Tensor2D
}