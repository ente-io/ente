import * as tf from '@tensorflow/tfjs-core';

import { ConvParams, SeparableConvParams } from '../common';
import { depthwiseSeparableConv } from '../common/depthwiseSeparableConv';
import { DenseBlock3Params, DenseBlock4Params } from './types';

export function denseBlock3(
  x: tf.Tensor4D,
  denseBlockParams: DenseBlock3Params,
  isFirstLayer: boolean = false
): tf.Tensor4D {
  return tf.tidy(() => {
    const out1 = tf.relu(
      isFirstLayer
        ? tf.add(
          tf.conv2d(x, (denseBlockParams.conv0 as ConvParams).filters, [2, 2], 'same'),
          denseBlockParams.conv0.bias
        )
        : depthwiseSeparableConv(x, denseBlockParams.conv0 as SeparableConvParams, [2, 2])
    ) as tf.Tensor4D
    const out2 = depthwiseSeparableConv(out1, denseBlockParams.conv1, [1, 1])

    const in3 = tf.relu(tf.add(out1, out2)) as tf.Tensor4D
    const out3 = depthwiseSeparableConv(in3, denseBlockParams.conv2, [1, 1])

    return tf.relu(tf.add(out1, tf.add(out2, out3))) as tf.Tensor4D
  })
}

export function denseBlock4(
  x: tf.Tensor4D,
  denseBlockParams: DenseBlock4Params,
  isFirstLayer: boolean = false,
  isScaleDown: boolean = true
): tf.Tensor4D {
  return tf.tidy(() => {
    const out1 = tf.relu(
      isFirstLayer
        ? tf.add(
          tf.conv2d(x, (denseBlockParams.conv0 as ConvParams).filters, isScaleDown ? [2, 2] : [1, 1], 'same'),
          denseBlockParams.conv0.bias
        )
        : depthwiseSeparableConv(x, denseBlockParams.conv0 as SeparableConvParams, isScaleDown ? [2, 2] : [1, 1])
    ) as tf.Tensor4D
    const out2 = depthwiseSeparableConv(out1, denseBlockParams.conv1, [1, 1])

    const in3 = tf.relu(tf.add(out1, out2)) as tf.Tensor4D
    const out3 = depthwiseSeparableConv(in3, denseBlockParams.conv2, [1, 1])

    const in4 = tf.relu(tf.add(out1, tf.add(out2, out3))) as tf.Tensor4D
    const out4 = depthwiseSeparableConv(in4, denseBlockParams.conv3, [1, 1])

    return tf.relu(tf.add(out1, tf.add(out2, tf.add(out3, out4)))) as tf.Tensor4D
  })
}
