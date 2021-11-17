import { env } from '../env';
import { resolveInput } from './resolveInput';

export function getContext2dOrThrow(canvasArg: string | HTMLCanvasElement | CanvasRenderingContext2D): CanvasRenderingContext2D {

  const { Canvas, CanvasRenderingContext2D } = env.getEnv()

  if (canvasArg instanceof CanvasRenderingContext2D) {
    return canvasArg
  }

  const canvas = resolveInput(canvasArg)

  if (!(canvas instanceof Canvas)) {
    throw new Error('resolveContext2d - expected canvas to be of instance of Canvas')
  }

  const ctx = canvas.getContext('2d')
  if (!ctx) {
    throw new Error('resolveContext2d - canvas 2d context is null')
  }

  return ctx
}