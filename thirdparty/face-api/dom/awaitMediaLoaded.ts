import { env } from '../env';
import { isMediaLoaded } from './isMediaLoaded';

export function awaitMediaLoaded(media: HTMLImageElement | HTMLVideoElement | HTMLCanvasElement) {

  return new Promise((resolve, reject) => {
    if (media instanceof env.getEnv().Canvas || isMediaLoaded(media)) {
      return resolve(null)
    }

    function onLoad(e: Event) {
      if (!e.currentTarget) return
      e.currentTarget.removeEventListener('load', onLoad)
      e.currentTarget.removeEventListener('error', onError)
      resolve(e)
    }

    function onError(e: Event) {
      if (!e.currentTarget) return
      e.currentTarget.removeEventListener('load', onLoad)
      e.currentTarget.removeEventListener('error', onError)
      reject(e)
    }

    media.addEventListener('load', onLoad)
    media.addEventListener('error', onError)
  })
}