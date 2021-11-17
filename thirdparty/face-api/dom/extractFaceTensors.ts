import * as tf from '@tensorflow/tfjs-core';

import { Rect } from '../classes';
import { FaceDetection } from '../classes/FaceDetection';
import { isTensor3D, isTensor4D } from '../utils';

/**
 * Extracts the tensors of the image regions containing the detected faces.
 * Useful if you want to compute the face descriptors for the face images.
 * Using this method is faster then extracting a canvas for each face and
 * converting them to tensors individually.
 *
 * @param imageTensor The image tensor that face detection has been performed on.
 * @param detections The face detection results or face bounding boxes for that image.
 * @returns Tensors of the corresponding image region for each detected face.
 */
export async function extractFaceTensors(
  imageTensor: tf.Tensor3D | tf.Tensor4D,
  detections: Array<FaceDetection | Rect>
): Promise<tf.Tensor3D[]> {

  if (!isTensor3D(imageTensor) && !isTensor4D(imageTensor)) {
    throw new Error('extractFaceTensors - expected image tensor to be 3D or 4D')
  }

  if (isTensor4D(imageTensor) && imageTensor.shape[0] > 1) {
    throw new Error('extractFaceTensors - batchSize > 1 not supported')
  }

  return tf.tidy(() => {
    const [imgHeight, imgWidth, numChannels] = imageTensor.shape.slice(isTensor4D(imageTensor) ? 1 : 0)

    const boxes = detections.map(
      det => det instanceof FaceDetection
        ? det.forSize(imgWidth, imgHeight).box
        : det
    )
      .map(box => box.clipAtImageBorders(imgWidth, imgHeight))

    const faceTensors = boxes.map(({ x, y, width, height }) =>
      tf.slice3d(imageTensor.as3D(imgHeight, imgWidth, numChannels), [y, x, 0], [height, width, numChannels])
    )

    return faceTensors
  })
}