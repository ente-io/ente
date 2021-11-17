import * as tf from '@tensorflow/tfjs-core';

import { IDimensions, Point } from '../classes';
import { FaceLandmarks68 } from '../classes/FaceLandmarks68';
import { NetInput, TNetInput, toNetInput } from '../dom';
import { FaceFeatureExtractorParams, TinyFaceFeatureExtractorParams } from '../faceFeatureExtractor/types';
import { FaceProcessor } from '../faceProcessor/FaceProcessor';
import { isEven } from '../utils';

export abstract class FaceLandmark68NetBase<
  TExtractorParams extends FaceFeatureExtractorParams | TinyFaceFeatureExtractorParams
>
  extends FaceProcessor<TExtractorParams> {

  public postProcess(output: tf.Tensor2D, inputSize: number, originalDimensions: IDimensions[]): tf.Tensor2D {

    const inputDimensions = originalDimensions.map(({ width, height }) => {
      const scale = inputSize / Math.max(height, width)
      return {
        width: width * scale,
        height: height * scale
      }
    })

    const batchSize = inputDimensions.length

    return tf.tidy(() => {
      const createInterleavedTensor = (fillX: number, fillY: number) =>
        tf.stack([
          tf.fill([68], fillX),
          tf.fill([68], fillY)
        ], 1).as2D(1, 136).as1D()

      const getPadding = (batchIdx: number, cond: (w: number, h: number) => boolean): number => {
        const { width, height } = inputDimensions[batchIdx]
        return cond(width, height) ? Math.abs(width - height) / 2 : 0
      }
      const getPaddingX = (batchIdx: number) => getPadding(batchIdx, (w, h) => w < h)
      const getPaddingY = (batchIdx: number) => getPadding(batchIdx, (w, h) => h < w)

      const landmarkTensors = output
        .mul(tf.fill([batchSize, 136], inputSize))
        .sub(tf.stack(Array.from(Array(batchSize), (_, batchIdx) =>
          createInterleavedTensor(
            getPaddingX(batchIdx),
            getPaddingY(batchIdx)
          )
        )))
        .div(tf.stack(Array.from(Array(batchSize), (_, batchIdx) =>
          createInterleavedTensor(
            inputDimensions[batchIdx].width,
            inputDimensions[batchIdx].height
          )
        )))

      return landmarkTensors as tf.Tensor2D
    })
  }

  public forwardInput(input: NetInput): tf.Tensor2D {
    return tf.tidy(() => {
      const out = this.runNet(input)
      return this.postProcess(
        out,
        input.inputSize as number,
        input.inputDimensions.map(([height, width]) => ({ height, width }))
      )
    })
  }

  public async forward(input: TNetInput): Promise<tf.Tensor2D> {
    return this.forwardInput(await toNetInput(input))
  }

  public async detectLandmarks(input: TNetInput): Promise<FaceLandmarks68 | FaceLandmarks68[]> {
    const netInput = await toNetInput(input)
    const landmarkTensors = tf.tidy(
      () => tf.unstack(this.forwardInput(netInput))
    )

    const landmarksForBatch = await Promise.all(landmarkTensors.map(
      async (landmarkTensor, batchIdx) => {
        const landmarksArray = Array.from(await landmarkTensor.data())
        const xCoords = landmarksArray.filter((_, i) => isEven(i))
        const yCoords = landmarksArray.filter((_, i) => !isEven(i))

        return new FaceLandmarks68(
          Array(68).fill(0).map((_, i) => new Point(xCoords[i], yCoords[i])),
          {
            height: netInput.getInputHeight(batchIdx),
            width : netInput.getInputWidth(batchIdx),
          }
        )
      }
    ))

    landmarkTensors.forEach(t => t.dispose())

    return netInput.isBatchInput
      ? landmarksForBatch
      : landmarksForBatch[0]
  }

  protected getClassifierChannelsOut(): number {
    return 136
  }
}