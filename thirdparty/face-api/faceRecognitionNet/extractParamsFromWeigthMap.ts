import * as tf from '@tensorflow/tfjs-core';

import { disposeUnusedWeightTensors, extractWeightEntryFactory, ParamMapping } from '../common';
import { isTensor2D } from '../utils';
import { ConvLayerParams, NetParams, ResidualLayerParams, ScaleLayerParams } from './types';

function extractorsFactory(weightMap: any, paramMappings: ParamMapping[]) {

  const extractWeightEntry = extractWeightEntryFactory(weightMap, paramMappings)

  function extractScaleLayerParams(prefix: string): ScaleLayerParams {

    const weights = extractWeightEntry<tf.Tensor1D>(`${prefix}/scale/weights`, 1)
    const biases = extractWeightEntry<tf.Tensor1D>(`${prefix}/scale/biases`, 1)

    return { weights, biases }
  }

  function extractConvLayerParams(prefix: string): ConvLayerParams {

    const filters = extractWeightEntry<tf.Tensor4D>(`${prefix}/conv/filters`, 4)
    const bias = extractWeightEntry<tf.Tensor1D>(`${prefix}/conv/bias`, 1)
    const scale = extractScaleLayerParams(prefix)

    return { conv: { filters, bias }, scale }
  }

  function extractResidualLayerParams(prefix: string): ResidualLayerParams {
    return {
      conv1: extractConvLayerParams(`${prefix}/conv1`),
      conv2: extractConvLayerParams(`${prefix}/conv2`)
    }
  }

  return {
    extractConvLayerParams,
    extractResidualLayerParams
  }

}

export function extractParamsFromWeigthMap(
  weightMap: tf.NamedTensorMap
): { params: NetParams, paramMappings: ParamMapping[] } {

  const paramMappings: ParamMapping[] = []

  const {
    extractConvLayerParams,
    extractResidualLayerParams
  } = extractorsFactory(weightMap, paramMappings)

  const conv32_down = extractConvLayerParams('conv32_down')
  const conv32_1 = extractResidualLayerParams('conv32_1')
  const conv32_2 = extractResidualLayerParams('conv32_2')
  const conv32_3 = extractResidualLayerParams('conv32_3')

  const conv64_down = extractResidualLayerParams('conv64_down')
  const conv64_1 = extractResidualLayerParams('conv64_1')
  const conv64_2 = extractResidualLayerParams('conv64_2')
  const conv64_3 = extractResidualLayerParams('conv64_3')

  const conv128_down = extractResidualLayerParams('conv128_down')
  const conv128_1 = extractResidualLayerParams('conv128_1')
  const conv128_2 = extractResidualLayerParams('conv128_2')

  const conv256_down = extractResidualLayerParams('conv256_down')
  const conv256_1 = extractResidualLayerParams('conv256_1')
  const conv256_2 = extractResidualLayerParams('conv256_2')
  const conv256_down_out = extractResidualLayerParams('conv256_down_out')

  const fc = weightMap['fc']
  paramMappings.push({ originalPath: 'fc', paramPath: 'fc' })

  if (!isTensor2D(fc)) {
    throw new Error(`expected weightMap[fc] to be a Tensor2D, instead have ${fc}`)
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

  disposeUnusedWeightTensors(weightMap, paramMappings)

  return { params, paramMappings }
}