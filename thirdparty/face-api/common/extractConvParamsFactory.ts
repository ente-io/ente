import * as tf from '@tensorflow/tfjs-core';

import { ConvParams, ExtractWeightsFunction, ParamMapping } from './types';

export function extractConvParamsFactory(
  extractWeights: ExtractWeightsFunction,
  paramMappings: ParamMapping[]
) {

  return function(
    channelsIn: number,
    channelsOut: number,
    filterSize: number,
    mappedPrefix: string
  ): ConvParams {

    const filters = tf.tensor4d(
      extractWeights(channelsIn * channelsOut * filterSize * filterSize),
      [filterSize, filterSize, channelsIn, channelsOut]
    )
    const bias = tf.tensor1d(extractWeights(channelsOut))

    paramMappings.push(
      { paramPath: `${mappedPrefix}/filters` },
      { paramPath: `${mappedPrefix}/bias` }
    )

    return { filters, bias }
  }

}
