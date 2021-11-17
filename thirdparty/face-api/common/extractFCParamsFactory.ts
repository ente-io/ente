import * as tf from '@tensorflow/tfjs-core';

import { ExtractWeightsFunction, FCParams, ParamMapping } from './types';


export function extractFCParamsFactory(
  extractWeights: ExtractWeightsFunction,
  paramMappings: ParamMapping[]
) {

  return function(
    channelsIn: number,
    channelsOut: number,
    mappedPrefix: string
  ): FCParams {

    const fc_weights = tf.tensor2d(extractWeights(channelsIn * channelsOut), [channelsIn, channelsOut])
    const fc_bias = tf.tensor1d(extractWeights(channelsOut))

    paramMappings.push(
      { paramPath: `${mappedPrefix}/weights` },
      { paramPath: `${mappedPrefix}/bias` }
    )

    return {
      weights: fc_weights,
      bias: fc_bias
    }
  }

}
