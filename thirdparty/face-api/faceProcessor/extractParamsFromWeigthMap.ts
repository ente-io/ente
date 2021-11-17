import * as tf from '@tensorflow/tfjs-core';

import { disposeUnusedWeightTensors, extractWeightEntryFactory, FCParams, ParamMapping } from '../common';
import { NetParams } from './types';

export function extractParamsFromWeigthMap(
  weightMap: tf.NamedTensorMap
): { params: NetParams, paramMappings: ParamMapping[] } {

  const paramMappings: ParamMapping[] = []

  const extractWeightEntry = extractWeightEntryFactory(weightMap, paramMappings)

  function extractFcParams(prefix: string): FCParams {
    const weights = extractWeightEntry<tf.Tensor2D>(`${prefix}/weights`, 2)
    const bias = extractWeightEntry<tf.Tensor1D>(`${prefix}/bias`, 1)
    return { weights, bias }
  }

  const params = {
    fc: extractFcParams('fc')
  }

  disposeUnusedWeightTensors(weightMap, paramMappings)

  return { params, paramMappings }
}