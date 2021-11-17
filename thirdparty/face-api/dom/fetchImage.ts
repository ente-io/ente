import { bufferToImage } from './bufferToImage';
import { fetchOrThrow } from './fetchOrThrow';

export async function fetchImage(uri: string): Promise<HTMLImageElement> {
  const res = await fetchOrThrow(uri)
  const blob = await (res).blob()

  if (!blob.type.startsWith('image/')) {
    throw new Error(`fetchImage - expected blob type to be of type image/*, instead have: ${blob.type}, for url: ${res.url}`)
  }
  return bufferToImage(blob)
}
