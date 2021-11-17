import { FaceRecognitionNet } from './FaceRecognitionNet';

export * from './FaceRecognitionNet';

export function createFaceRecognitionNet(weights: Float32Array) {
  const net = new FaceRecognitionNet()
  net.extractWeights(weights)
  return net
}