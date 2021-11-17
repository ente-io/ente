import { getCenterPoint } from '../utils';
import { FaceLandmarks } from './FaceLandmarks';
import { Point } from './Point';

export class FaceLandmarks68 extends FaceLandmarks {
  public getJawOutline(): Point[] {
    return this.positions.slice(0, 17)
  }

  public getLeftEyeBrow(): Point[] {
    return this.positions.slice(17, 22)
  }

  public getRightEyeBrow(): Point[] {
    return this.positions.slice(22, 27)
  }

  public getNose(): Point[] {
    return this.positions.slice(27, 36)
  }

  public getLeftEye(): Point[] {
    return this.positions.slice(36, 42)
  }

  public getRightEye(): Point[] {
    return this.positions.slice(42, 48)
  }

  public getMouth(): Point[] {
    return this.positions.slice(48, 68)
  }

  protected getRefPointsForAlignment(): Point[] {
    return [
      this.getLeftEye(),
      this.getRightEye(),
      this.getMouth()
    ].map(getCenterPoint)
  }
}