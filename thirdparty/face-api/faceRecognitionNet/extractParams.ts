import * as tf from '@tensorflow/tfjs-core';

import { ConvParams, extractWeightsFactory, ExtractWeightsFunction, ParamMapping } from '../common';
import { isFloat } from '../utils';
import { ConvLayerParams, NetParams, ResidualLayerParams, ScaleLayerParams } from './types';

function extractorsFactory(extractWeights: ExtractWeightsFunction, paramMappings: ParamMapping[]) {

  function extractFilterValues(numFilterValues: number, numFilters: number, filterSize: number): tf.Tensor4D {
    const weights = extractWeights(numFilterValues)
    const depth = weights.length / (numFilters * filterSize * filterSize)

    if (isFloat(depth)) {
      throw new Error(`depth has to be an integer: ${depth}, weights.length: ${weights.length}, numFilters: ${numFilters}, filterSize: ${filterSize}`)
    }

    return tf.tidy(
      () => tf.transpose(
        tf.tensor4d(weights, [numFilters, depth, filterSize, filterSize]),
        [2, 3, 1, 0]
      )
    )
  }

  function extractConvParams(
    numFilterValues: number,
    numFilters: number,
    filterSize: number,
    mappedPrefix: string
  ): ConvParams {

    const filters = extractFilterValues(numFilterValues, numFilters, filterSize)
    const bias = tf.tensor1d(extractWeights(numFilters))

    paramMappings.push(
      { paramPath: `${mappedPrefix}/filters` },
      { paramPath: `${mappedPrefix}/bias` }
    )

    return { filters, bias }
  }

  function extractScaleLayerParams(numWeights: number, mappedPrefix: string): ScaleLayerParams {

    const weights = tf.tensor1d(extractWeights(numWeights))
    const biases = tf.tensor1d(extractWeights(numWeights))

    paramMappings.push(
      { paramPath: `${mappedPrefix}/weights` },
      { paramPath: `${mappedPrefix}/biases` }
    )

    return {
      weights,
      biases
    }
  }

  function extractConvLayerParams(
    numFilterValues: number,
    numFilters: number,
    filterSize: number,
    mappedPrefix: string
  ): ConvLayerParams {

    const conv = extractConvParams(numFilterValues, numFilters, filterSize, `${mappedPrefix}/conv`)
    const scale = extractScaleLayerParams(numFilters, `${mappedPrefix}/scale`)

    return { conv, scale }
  }

  function extractResidualLayerParams(
    numFilterValues: number,
    numFilters: number,
    filterSize: number,
    mappedPrefix: string,
    isDown: boolean = false
  ): ResidualLayerParams {

    const conv1 = extractConvLayerParams((isDown ? 0.5 : 1) * numFilterValues, numFilters, filterSize, `${mappedPrefix}/conv1`)
    const conv2 = extractConvLayerParams(numFilterValues, numFilters, filterSize, `${mappedPrefix}/conv2`)

    return { conv1, conv2 }
  }

  return {
    extractConvLayerParams,
    extractResidualLayerParams
  }

}

export function extractParams(weights: Float32Array): { params: NetParams, paramMappings: ParamMapping[] } {

  const {
    extractWeights,
    getRemainingWeights
  } = extractWeightsFactory(weights)

  const paramMappings: ParamMapping[] = []

  const {
    extractConvLayerParams,
    extractResidualLayerParams
  } = extractorsFactory(extractWeights, paramMappings)

  const conv32_down = extractConvLayerParams(4704, 32, 7, 'conv32_down')
  const conv32_1 = extractResidualLayerParams(9216, 32, 3, 'conv32_1')
  const conv32_2 = extractResidualLayerParams(9216, 32, 3, 'conv32_2')
  const conv32_3 = extractResidualLayerParams(9216, 32, 3, 'conv32_3')

  const conv64_down = extractResidualLayerParams(36864, 64, 3, 'conv64_down', true)
  const conv64_1 = extractResidualLayerParams(36864, 64, 3, 'conv64_1')
  const conv64_2 = extractResidualLayerParams(36864, 64, 3, 'conv64_2')
  const conv64_3 = extractResidualLayerParams(36864, 64, 3, 'conv64_3')

  const conv128_down = extractResidualLayerParams(147456, 128, 3, 'conv128_down', true)
  const conv128_1 = extractResidualLayerParams(147456, 128, 3, 'conv128_1')
  const conv128_2 = extractResidualLayerParams(147456, 128, 3, 'conv128_2')

  const conv256_down = extractResidualLayerParams(589824, 256, 3, 'conv256_down', true)
  const conv256_1 = extractResidualLayerParams(589824, 256, 3, 'conv256_1')
  const conv256_2 = extractResidualLayerParams(589824, 256, 3, 'conv256_2')
  const conv256_down_out = extractResidualLayerParams(589824, 256, 3, 'conv256_down_out')

  const fc = tf.tidy(
    () => tf.transpose(tf.tensor2d(extractWeights(256 * 128), [128, 256]), [1, 0])
  )
  paramMappings.push({ paramPath: `fc` })

  if (getRemainingWeights().length !== 0) {
    throw new Error(`weights remaing after extract: ${getRemainingWeights().length}`)
  }

  const params = {
    conv32_down,
    conv32_1,
    conv32_2,
    conv32_3,
    conv64_down,
    conv64_1,
    conv64_2,
    conv64_3,
    conv128_down,
    conv128_1,
    conv128_2,
    conv256_down,
    conv256_1,
    conv256_2,
    conv256_down_out,
    fc
  }

  return { params, paramMappings }
}