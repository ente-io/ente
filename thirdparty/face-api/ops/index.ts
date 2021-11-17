export * from './iou'
export * from './minBbox'
export * from './nonMaxSuppression'
export * from './normalize'
export * from './padToSquare'
export * from './shuffleArray'

export function sigmoid(x: number) {
  return 1 / (1 + Math.exp(-x))
}

export function inverseSigmoid(x: number) {
  return Math.log(x / (1 - x))
}