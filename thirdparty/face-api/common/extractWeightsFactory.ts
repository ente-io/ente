export function extractWeightsFactory(weights: Float32Array) {
  let remainingWeights = weights

  function extractWeights(numWeights: number): Float32Array {
    const ret = remainingWeights.slice(0, numWeights)
    remainingWeights = remainingWeights.slice(numWeights)
    return ret
  }

  function getRemainingWeights(): Float32Array {
    return remainingWeights
  }

  return {
    extractWeights,
    getRemainingWeights
  }
}