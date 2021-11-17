import * as tf from '@tensorflow/tfjs-core';

import { NetInput } from './NetInput';

export type TMediaElement = HTMLImageElement | HTMLVideoElement | HTMLCanvasElement

export type TResolvedNetInput = TMediaElement | tf.Tensor3D | tf.Tensor4D

export type TNetInputArg = string | TResolvedNetInput

export type TNetInput = TNetInputArg | Array<TNetInputArg> | NetInput | tf.Tensor4D