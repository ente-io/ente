import { fetchOrThrow } from './fetchOrThrow';

export async function fetchJson<T>(uri: string): Promise<T> {
  return (await fetchOrThrow(uri)).json()
}
