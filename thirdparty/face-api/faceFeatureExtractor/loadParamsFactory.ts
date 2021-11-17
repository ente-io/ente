import { extractWeightEntryFactory, loadSeparableConvParamsFactory, ParamMapping } from '../common';
import { loadConvParamsFactory } from '../common/loadConvParamsFactory';
import { DenseBlock3Params, DenseBlock4Params } from './types';

export function loadParamsFactory(weightMap: any, paramMappings: ParamMapping[]) {

  const extractWeightEntry = extractWeightEntryFactory(weightMap, paramMappings)

  const extractConvParams = loadConvParamsFactory(extractWeightEntry)
  const extractSeparableConvParams = loadSeparableConvParamsFactory(extractWeightEntry)

  function extractDenseBlock3Params(prefix: string, isFirstLayer: boolean = false): DenseBlock3Params {
    const conv0 = isFirstLayer
      ? extractConvParams(`${prefix}/conv0`)
      : extractSeparableConvParams(`${prefix}/conv0`)
    const conv1 = extractSeparableConvParams(`${prefix}/conv1`)
    const conv2 = extractSeparableConvParams(`${prefix}/conv2`)

    return { conv0, conv1, conv2 }
  }

  function extractDenseBlock4Params(prefix: string, isFirstLayer: boolean = false): DenseBlock4Params {
    const conv0 = isFirstLayer
      ? extractConvParams(`${prefix}/conv0`)
      : extractSeparableConvParams(`${prefix}/conv0`)
    const conv1 = extractSeparableConvParams(`${prefix}/conv1`)
    const conv2 = extractSeparableConvParams(`${prefix}/conv2`)
    const conv3 = extractSeparableConvParams(`${prefix}/conv3`)

    return { conv0, conv1, conv2, conv3 }
  }

  return {
    extractDenseBlock3Params,
    extractDenseBlock4Params
  }
}