import * as tf from '@tensorflow/tfjs-core';

export function seperateWeightMaps(weightMap: tf.NamedTensorMap) {

  const featureExtractorMap: tf.NamedTensorMap = {}
  const classifierMap: tf.NamedTensorMap = {}

  Object.keys(weightMap).forEach(key => {
    const map = key.startsWith('fc') ? classifierMap : featureExtractorMap
    map[key] = weightMap[key]
  })

  return { featureExtractorMap, classifierMap }

}