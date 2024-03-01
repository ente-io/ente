import { isValidNumber } from '../utils';

export interface IDimensions {
  width: number
  height: number
}

export class Dimensions implements IDimensions {

  private _width: number
  private _height: number

  constructor(width: number, height: number) {
    if (!isValidNumber(width) || !isValidNumber(height)) {
      throw new Error(`Dimensions.constructor - expected width and height to be valid numbers, instead have ${JSON.stringify({ width, height })}`)
    }

    this._width = width
    this._height = height
  }

  public get width(): number { return this._width }
  public get height(): number { return this._height }

  public reverse(): Dimensions {
    return new Dimensions(1 / this.width, 1 / this.height)
  }
}