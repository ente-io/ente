import { FaceDetection } from '../classes/FaceDetection';
import { Rect } from '../classes/Rect';
import { env } from '../env';
import { createCanvas } from './createCanvas';
import { getContext2dOrThrow } from './getContext2dOrThrow';
import { imageTensorToCanvas } from './imageTensorToCanvas';
import { toNetInput } from './toNetInput';
import { TNetInput } from './types';

/**
 * Extracts the image regions containing the detected faces.
 *
 * @param input The image that face detection has been performed on.
 * @param detections The face detection results or face bounding boxes for that image.
 * @returns The Canvases of the corresponding image region for each detected face.
 */
export async function extractFaces(
  input: TNetInput,
  detections: Array<FaceDetection | Rect>
): Promise<HTMLCanvasElement[]> {

  const { Canvas } = env.getEnv()

  let canvas = input as HTMLCanvasElement

  if (!(input instanceof Canvas)) {
    const netInput = await toNetInput(input)

    if (netInput.batchSize > 1) {
      throw new Error('extractFaces - batchSize > 1 not supported')
    }

    const tensorOrCanvas = netInput.getInput(0)
    canvas = tensorOrCanvas instanceof Canvas
      ? tensorOrCanvas
      : await imageTensorToCanvas(tensorOrCanvas)
  }

  const ctx = getContext2dOrThrow(canvas)
  const boxes = detections.map(
    det => det instanceof FaceDetection
      ? det.forSize(canvas.width, canvas.height).box.floor()
      : det
  )
    .map(box => box.clipAtImageBorders(canvas.width, canvas.height))

  return boxes.map(({ x, y, width, height }) => {
    const faceImg = createCanvas({ width, height })
    getContext2dOrThrow(faceImg)
      .putImageData(ctx.getImageData(x, y, width, height), 0, 0)
    return faceImg
  })
}