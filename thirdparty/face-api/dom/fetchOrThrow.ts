import { env } from '../env';

export async function fetchOrThrow(
  url: string,
  init?: RequestInit
): Promise<Response> {

  const fetch = env.getEnv().fetch
  const res = await fetch(url, init)
  if (!(res.status < 400)) {
    throw new Error(`failed to fetch: (${res.status}) ${res.statusText}, from url: ${res.url}`)
  }
  return res
}