import * as tf from '@tensorflow/tfjs-core';

import { ExtractWeightsFunction, ParamMapping, SeparableConvParams } from './types';

export function extractSeparableConvParamsFactory(
  extractWeights: ExtractWeightsFunction,
  paramMappings: ParamMapping[]
) {

  return function(channelsIn: number, channelsOut: number, mappedPrefix: string): SeparableConvParams {
    const depthwise_filter = tf.tensor4d(extractWeights(3 * 3 * channelsIn), [3, 3, channelsIn, 1])
    const pointwise_filter = tf.tensor4d(extractWeights(channelsIn * channelsOut), [1, 1, channelsIn, channelsOut])
    const bias = tf.tensor1d(extractWeights(channelsOut))

    paramMappings.push(
      { paramPath: `${mappedPrefix}/depthwise_filter` },
      { paramPath: `${mappedPrefix}/pointwise_filter` },
      { paramPath: `${mappedPrefix}/bias` }
    )

    return new SeparableConvParams(
      depthwise_filter,
      pointwise_filter,
      bias
    )
  }

}

export function loadSeparableConvParamsFactory(
  extractWeightEntry: <T>(originalPath: string, paramRank: number) => T
) {

  return function (prefix: string): SeparableConvParams {
    const depthwise_filter = extractWeightEntry<tf.Tensor4D>(`${prefix}/depthwise_filter`, 4)
    const pointwise_filter = extractWeightEntry<tf.Tensor4D>(`${prefix}/pointwise_filter`, 4)
    const bias = extractWeightEntry<tf.Tensor1D>(`${prefix}/bias`, 1)

    return new SeparableConvParams(
      depthwise_filter,
      pointwise_filter,
      bias
    )
  }

}
