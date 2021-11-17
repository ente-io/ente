import { minBbox } from '../ops';
import { getCenterPoint } from '../utils';
import { IBoundingBox } from './BoundingBox';
import { Box } from './Box';
import { Dimensions, IDimensions } from './Dimensions';
import { FaceDetection } from './FaceDetection';
import { Point } from './Point';
import { IRect, Rect } from './Rect';

// face alignment constants
const relX = 0.5
const relY = 0.43
const relScale = 0.45

export interface IFaceLandmarks {
  positions: Point[]
  shift: Point
}

export class FaceLandmarks implements IFaceLandmarks {
  protected _shift: Point
  protected _positions: Point[]
  protected _imgDims: Dimensions

  constructor(
    relativeFaceLandmarkPositions: Point[],
    imgDims: IDimensions,
    shift: Point = new Point(0, 0)
  ) {
    const { width, height } = imgDims
    this._imgDims = new Dimensions(width, height)
    this._shift = shift
    this._positions = relativeFaceLandmarkPositions.map(
      pt => pt.mul(new Point(width, height)).add(shift)
    )
  }

  public get shift(): Point { return new Point(this._shift.x, this._shift.y) }
  public get imageWidth(): number { return this._imgDims.width }
  public get imageHeight(): number { return this._imgDims.height }
  public get positions(): Point[] { return this._positions }
  public get relativePositions(): Point[] {
    return this._positions.map(
      pt => pt.sub(this._shift).div(new Point(this.imageWidth, this.imageHeight))
    )
  }

  public forSize<T extends FaceLandmarks>(width: number, height: number): T {
    return new (this.constructor as any)(
      this.relativePositions,
      { width, height }
    )
  }

  public shiftBy<T extends FaceLandmarks>(x: number, y: number): T {
    return new (this.constructor as any)(
      this.relativePositions,
      this._imgDims,
      new Point(x, y)
    )
  }

  public shiftByPoint<T extends FaceLandmarks>(pt: Point): T {
    return this.shiftBy(pt.x, pt.y)
  }

  /**
   * Aligns the face landmarks after face detection from the relative positions of the faces
   * bounding box, or it's current shift. This function should be used to align the face images
   * after face detection has been performed, before they are passed to the face recognition net.
   * This will make the computed face descriptor more accurate.
   *
   * @param detection (optional) The bounding box of the face or the face detection result. If
   * no argument was passed the position of the face landmarks are assumed to be relative to
   * it's current shift.
   * @returns The bounding box of the aligned face.
   */
  public align(
    detection?: FaceDetection | IRect | IBoundingBox | null,
    options: { useDlibAlignment?: boolean, minBoxPadding?: number } = { }
  ): Box {
    if (detection) {
      const box = detection instanceof FaceDetection
        ? detection.box.floor()
        : new Box(detection)

      return this.shiftBy(box.x, box.y).align(null, options)
    }

    const { useDlibAlignment, minBoxPadding } = Object.assign({}, { useDlibAlignment: false, minBoxPadding: 0.2 }, options)

    if (useDlibAlignment) {
      return this.alignDlib()
    }

    return this.alignMinBbox(minBoxPadding)
  }

  private alignDlib(): Box {

    const centers = this.getRefPointsForAlignment()

    const [leftEyeCenter, rightEyeCenter, mouthCenter] = centers
    const distToMouth = (pt: Point) => mouthCenter.sub(pt).magnitude()
    const eyeToMouthDist = (distToMouth(leftEyeCenter) + distToMouth(rightEyeCenter)) / 2

    const size = Math.floor(eyeToMouthDist / relScale)

    const refPoint = getCenterPoint(centers)
    // TODO: pad in case rectangle is out of image bounds
    const x = Math.floor(Math.max(0, refPoint.x - (relX * size)))
    const y = Math.floor(Math.max(0, refPoint.y - (relY * size)))

    return new Rect(x, y, Math.min(size, this.imageWidth + x), Math.min(size, this.imageHeight + y))
  }

  private alignMinBbox(padding: number): Box {
    const box = minBbox(this.positions)
    return box.pad(box.width * padding, box.height * padding)
  }

  protected getRefPointsForAlignment(): Point[] {
    throw new Error('getRefPointsForAlignment not implemented by base class')
  }
}