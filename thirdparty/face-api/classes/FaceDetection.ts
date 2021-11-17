import { Box } from './Box';
import { IDimensions } from './Dimensions';
import { ObjectDetection } from './ObjectDetection';
import { Rect } from './Rect';

export interface IFaceDetecion {
  score: number
  box: Box
}

export class FaceDetection extends ObjectDetection implements IFaceDetecion {
  constructor(
    score: number,
    relativeBox: Rect,
    imageDims: IDimensions
  ) {
    super(score, score, '', relativeBox, imageDims)
  }

  public forSize(width: number, height: number): FaceDetection {
    const { score, relativeBox, imageDims } = super.forSize(width, height)
    return new FaceDetection(score, relativeBox, imageDims)
  }
}