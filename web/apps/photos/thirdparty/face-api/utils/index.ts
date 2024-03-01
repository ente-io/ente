import * as tf from '@tensorflow/tfjs-core';

import { Point } from '../classes';
import { Dimensions, IDimensions } from '../classes/Dimensions';

export function isTensor(tensor: any, dim: number) {
  return tensor instanceof tf.Tensor && tensor.shape.length === dim
}

export function isTensor1D(tensor: any): tensor is tf.Tensor1D {
  return isTensor(tensor, 1)
}

export function isTensor2D(tensor: any): tensor is tf.Tensor2D {
  return isTensor(tensor, 2)
}

export function isTensor3D(tensor: any): tensor is tf.Tensor3D {
  return isTensor(tensor, 3)
}

export function isTensor4D(tensor: any): tensor is tf.Tensor4D {
  return isTensor(tensor, 4)
}

export function isFloat(num: number) {
  return num % 1 !== 0
}

export function isEven(num: number) {
  return num % 2 === 0
}

export function round(num: number, prec: number = 2) {
  const f = Math.pow(10, prec)
  return Math.floor(num * f) / f
}

export function isDimensions(obj: any): boolean {
  return obj && obj.width && obj.height
}

export function computeReshapedDimensions({ width, height }: IDimensions, inputSize: number) {
  const scale = inputSize / Math.max(height, width)
  return new Dimensions(Math.round(width * scale), Math.round(height * scale))
}

export function getCenterPoint(pts: Point[]): Point {
  return pts.reduce((sum, pt) => sum.add(pt), new Point(0, 0))
    .div(new Point(pts.length, pts.length))
}

export function range(num: number, start: number, step: number): number[] {
  return Array(num).fill(0).map((_, i) => start + (i * step))
}

export function isValidNumber(num: any) {
  return !!num && num !== Infinity && num !== -Infinity && !isNaN(num) || num === 0
}

export function isValidProbablitiy(num: any) {
  return isValidNumber(num) && 0 <= num && num <= 1.0
}