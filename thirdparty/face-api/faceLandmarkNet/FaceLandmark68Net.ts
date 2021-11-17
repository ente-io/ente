import { FaceFeatureExtractor } from '../faceFeatureExtractor/FaceFeatureExtractor';
import { FaceFeatureExtractorParams } from '../faceFeatureExtractor/types';
import { FaceLandmark68NetBase } from './FaceLandmark68NetBase';

export class FaceLandmark68Net extends FaceLandmark68NetBase<FaceFeatureExtractorParams> {

  constructor(faceFeatureExtractor: FaceFeatureExtractor = new FaceFeatureExtractor()) {
    super('FaceLandmark68Net', faceFeatureExtractor)
  }

  protected getDefaultModelName(): string {
    return 'face_landmark_68_model'
  }

  protected getClassifierChannelsIn(): number {
    return 256
  }
}