import * as tf from '@tensorflow/tfjs-core';

import { Dimensions } from '../classes/Dimensions';
import { env } from '../env';
import { padToSquare } from '../ops/padToSquare';
import { computeReshapedDimensions, isTensor3D, isTensor4D, range } from '../utils';
import { createCanvasFromMedia } from './createCanvas';
import { imageToSquare } from './imageToSquare';
import { TResolvedNetInput } from './types';

export class NetInput {
  private _imageTensors: Array<tf.Tensor3D | tf.Tensor4D> = []
  private _canvases: HTMLCanvasElement[] = []
  private _batchSize: number
  private _treatAsBatchInput: boolean = false

  private _inputDimensions: number[][] = []
  private _inputSize: number

  constructor(
    inputs: Array<TResolvedNetInput>,
    treatAsBatchInput: boolean = false
  ) {
    if (!Array.isArray(inputs)) {
      throw new Error(`NetInput.constructor - expected inputs to be an Array of TResolvedNetInput or to be instanceof tf.Tensor4D, instead have ${inputs}`)
    }

    this._treatAsBatchInput = treatAsBatchInput
    this._batchSize = inputs.length

    inputs.forEach((input, idx) => {

      if (isTensor3D(input)) {
        this._imageTensors[idx] = input
        this._inputDimensions[idx] = input.shape
        return
      }

      if (isTensor4D(input)) {
        const batchSize = input.shape[0]
        if (batchSize !== 1) {
          throw new Error(`NetInput - tf.Tensor4D with batchSize ${batchSize} passed, but not supported in input array`)
        }

        this._imageTensors[idx] = input
        this._inputDimensions[idx] = input.shape.slice(1)
        return
      }

      const canvas = input instanceof env.getEnv().Canvas ? input : createCanvasFromMedia(input)
      this._canvases[idx] = canvas
      this._inputDimensions[idx] = [canvas.height, canvas.width, 3]
    })
  }

  public get imageTensors(): Array<tf.Tensor3D | tf.Tensor4D> {
    return this._imageTensors
  }

  public get canvases(): HTMLCanvasElement[] {
    return this._canvases
  }

  public get isBatchInput(): boolean {
    return this.batchSize > 1 || this._treatAsBatchInput
  }

  public get batchSize(): number {
    return this._batchSize
  }

  public get inputDimensions(): number[][] {
    return this._inputDimensions
  }

  public get inputSize(): number | undefined {
    return this._inputSize
  }

  public get reshapedInputDimensions(): Dimensions[] {
    return range(this.batchSize, 0, 1).map(
      (_, batchIdx) => this.getReshapedInputDimensions(batchIdx)
    )
  }

  public getInput(batchIdx: number): tf.Tensor3D  | tf.Tensor4D | HTMLCanvasElement {
    return this.canvases[batchIdx] || this.imageTensors[batchIdx]
  }

  public getInputDimensions(batchIdx: number): number[] {
    return this._inputDimensions[batchIdx]
  }

  public getInputHeight(batchIdx: number): number {
    return this._inputDimensions[batchIdx][0]
  }

  public getInputWidth(batchIdx: number): number {
    return this._inputDimensions[batchIdx][1]
  }

  public getReshapedInputDimensions(batchIdx: number): Dimensions {
    if (typeof this.inputSize !== 'number') {
      throw new Error('getReshapedInputDimensions - inputSize not set, toBatchTensor has not been called yet')
    }

    const width = this.getInputWidth(batchIdx)
    const height = this.getInputHeight(batchIdx)
    return computeReshapedDimensions({ width, height }, this.inputSize)
  }

  /**
   * Create a batch tensor from all input canvases and tensors
   * with size [batchSize, inputSize, inputSize, 3].
   *
   * @param inputSize Height and width of the tensor.
   * @param isCenterImage (optional, default: false) If true, add an equal amount of padding on
   * both sides of the minor dimension oof the image.
   * @returns The batch tensor.
   */
  public toBatchTensor(inputSize: number, isCenterInputs: boolean = true): tf.Tensor4D {

    this._inputSize = inputSize

    return tf.tidy(() => {

      const inputTensors = range(this.batchSize, 0, 1).map(batchIdx => {
        const input = this.getInput(batchIdx)

        if (input instanceof tf.Tensor) {
          let imgTensor = isTensor4D(input) ? input : input.expandDims<tf.Tensor4D>()
          imgTensor = padToSquare(imgTensor, isCenterInputs)

          if (imgTensor.shape[1] !== inputSize || imgTensor.shape[2] !== inputSize) {
            imgTensor = tf.image.resizeBilinear(imgTensor, [inputSize, inputSize])
          }

          return imgTensor.as3D(inputSize, inputSize, 3)
        }

        if (input instanceof env.getEnv().Canvas) {
          return tf.browser.fromPixels(imageToSquare(input, inputSize, isCenterInputs))
        }

        throw new Error(`toBatchTensor - at batchIdx ${batchIdx}, expected input to be instanceof tf.Tensor or instanceof HTMLCanvasElement, instead have ${input}`)
      })

      const batchTensor = tf.stack(inputTensors.map(t => t.toFloat())).as4D(this.batchSize, inputSize, inputSize, 3)

      return batchTensor
    })
  }
}