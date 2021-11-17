import { extractWeightsFactory, ParamMapping } from '../common';
import { extractorsFactory } from './extractorsFactory';
import { FaceFeatureExtractorParams } from './types';


export function extractParams(weights: Float32Array): { params: FaceFeatureExtractorParams, paramMappings: ParamMapping[] } {

  const paramMappings: ParamMapping[] = []

  const {
    extractWeights,
    getRemainingWeights
  } = extractWeightsFactory(weights)

  const {
    extractDenseBlock4Params
  } = extractorsFactory(extractWeights, paramMappings)

  const dense0 = extractDenseBlock4Params(3, 32, 'dense0', true)
  const dense1 = extractDenseBlock4Params(32, 64, 'dense1')
  const dense2 = extractDenseBlock4Params(64, 128, 'dense2')
  const dense3 = extractDenseBlock4Params(128, 256, 'dense3')

  if (getRemainingWeights().length !== 0) {
    throw new Error(`weights remaing after extract: ${getRemainingWeights().length}`)
  }

  return {
    paramMappings,
    params: { dense0, dense1, dense2, dense3 }
  }
}