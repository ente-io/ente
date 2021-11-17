import { IDimensions } from '../classes/Dimensions';
import { env } from '../env';
import { getContext2dOrThrow } from './getContext2dOrThrow';
import { getMediaDimensions } from './getMediaDimensions';
import { isMediaLoaded } from './isMediaLoaded';

export function createCanvas({ width, height }: IDimensions): HTMLCanvasElement {

  const { createCanvasElement } = env.getEnv()
  const canvas = createCanvasElement()
  canvas.width = width
  canvas.height = height
  return canvas
}

export function createCanvasFromMedia(media: HTMLImageElement | HTMLVideoElement | ImageData, dims?: IDimensions): HTMLCanvasElement {

  const { ImageData } = env.getEnv()

  if (!(media instanceof ImageData) && !isMediaLoaded(media)) {
    throw new Error('createCanvasFromMedia - media has not finished loading yet')
  }

  const { width, height } = dims || getMediaDimensions(media)
  const canvas = createCanvas({ width, height })

  if (media instanceof ImageData) {
    getContext2dOrThrow(canvas).putImageData(media, 0, 0)
  } else {
    getContext2dOrThrow(canvas).drawImage(media, 0, 0, width, height)
  }
  return canvas
}