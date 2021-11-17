import { fetchOrThrow } from './fetchOrThrow';

export async function fetchNetWeights(uri: string): Promise<Float32Array> {
  return new Float32Array(await (await fetchOrThrow(uri)).arrayBuffer())
}
