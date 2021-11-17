import * as tf from '@tensorflow/tfjs-core';

import { SeparableConvParams } from './types';

export function depthwiseSeparableConv(
  x: tf.Tensor4D,
  params: SeparableConvParams,
  stride: [number, number]
): tf.Tensor4D {
  return tf.tidy(() => {
    let out = tf.separableConv2d(x, params.depthwise_filter, params.pointwise_filter, stride, 'same')
    out = tf.add(out, params.bias)
    return out
  })
}