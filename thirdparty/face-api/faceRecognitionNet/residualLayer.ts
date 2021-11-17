import * as tf from '@tensorflow/tfjs-core';

import { conv, convDown, convNoRelu } from './convLayer';
import { ResidualLayerParams } from './types';

export function residual(x: tf.Tensor4D, params: ResidualLayerParams): tf.Tensor4D {
  let out = conv(x, params.conv1)
  out = convNoRelu(out, params.conv2)
  out = tf.add(out, x)
  out = tf.relu(out)
  return out
}

export function residualDown(x: tf.Tensor4D, params: ResidualLayerParams): tf.Tensor4D {
  let out = convDown(x, params.conv1)
  out = convNoRelu(out, params.conv2)

  let pooled = tf.avgPool(x, 2, 2, 'valid') as tf.Tensor4D
  const zeros = tf.zeros<tf.Rank.R4>(pooled.shape)
  const isPad = pooled.shape[3] !== out.shape[3]
  const isAdjustShape = pooled.shape[1] !== out.shape[1] || pooled.shape[2] !== out.shape[2]

  if (isAdjustShape) {
    const padShapeX = [...out.shape] as [number, number, number, number]
    padShapeX[1] = 1
    const zerosW = tf.zeros<tf.Rank.R4>(padShapeX)
    out = tf.concat([out, zerosW], 1)

    const padShapeY = [...out.shape] as [number, number, number, number]
    padShapeY[2] = 1
    const zerosH = tf.zeros<tf.Rank.R4>(padShapeY)
    out = tf.concat([out, zerosH], 2)
  }

  pooled = isPad ? tf.concat([pooled, zeros], 3) : pooled
  out = tf.add(pooled, out) as tf.Tensor4D

  out = tf.relu(out)
  return out
}