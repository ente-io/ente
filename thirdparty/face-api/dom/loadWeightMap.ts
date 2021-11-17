import * as tf from '@tensorflow/tfjs-core';

import { getModelUris } from '../common/getModelUris';
import { fetchJson } from './fetchJson';

export async function loadWeightMap(
  uri: string | undefined,
  defaultModelName: string,
): Promise<tf.NamedTensorMap> {
  const { manifestUri, modelBaseUri } = getModelUris(uri, defaultModelName)

  const manifest = await fetchJson<tf.io.WeightsManifestConfig>(manifestUri)

  return tf.io.loadWeights(manifest, modelBaseUri)
}