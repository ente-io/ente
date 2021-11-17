import { env } from '../env';

export function isMediaLoaded(media: HTMLImageElement | HTMLVideoElement) : boolean {

  const { Image, Video } = env.getEnv()

  return (media instanceof Image && media.complete)
    || (media instanceof Video && media.readyState >= 3)
}
