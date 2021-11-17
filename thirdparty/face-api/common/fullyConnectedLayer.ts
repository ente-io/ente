import * as tf from '@tensorflow/tfjs-core';

import { FCParams } from './types';

export function fullyConnectedLayer(
  x: tf.Tensor2D,
  params: FCParams
): tf.Tensor2D {
  return tf.tidy(() =>
    tf.add(
      tf.matMul(x, params.weights),
      params.bias
    )
  )
}