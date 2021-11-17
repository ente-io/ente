import { isDimensions, isValidNumber } from '../utils';
import { IBoundingBox } from './BoundingBox';
import { IDimensions } from './Dimensions';
import { Point } from './Point';
import { IRect } from './Rect';

export class Box<BoxType = any> implements IBoundingBox, IRect {

  public static isRect(rect: any): boolean {
    return !!rect && [rect.x, rect.y, rect.width, rect.height].every(isValidNumber)
  }

  public static assertIsValidBox(box: any, callee: string, allowNegativeDimensions: boolean = false) {
    if (!Box.isRect(box)) {
      throw new Error(`${callee} - invalid box: ${JSON.stringify(box)}, expected object with properties x, y, width, height`)
    }

    if (!allowNegativeDimensions && (box.width < 0 || box.height < 0)) {
      throw new Error(`${callee} - width (${box.width}) and height (${box.height}) must be positive numbers`)
    }
  }

  private _x: number
  private _y: number
  private _width: number
  private _height: number

  constructor(_box: IBoundingBox | IRect, allowNegativeDimensions: boolean = true) {
    const box = (_box || {}) as any

    const isBbox = [box.left, box.top, box.right, box.bottom].every(isValidNumber)
    const isRect = [box.x, box.y, box.width, box.height].every(isValidNumber)

    if (!isRect && !isBbox) {
      throw new Error(`Box.constructor - expected box to be IBoundingBox | IRect, instead have ${JSON.stringify(box)}`)
    }

    const [x, y, width, height] = isRect
      ? [box.x, box.y, box.width, box.height]
      : [box.left, box.top, box.right - box.left, box.bottom - box.top]

    Box.assertIsValidBox({ x, y, width, height }, 'Box.constructor', allowNegativeDimensions)

    this._x = x
    this._y = y
    this._width = width
    this._height = height
  }

  public get x(): number { return this._x }
  public get y(): number { return this._y }
  public get width(): number { return this._width }
  public get height(): number { return this._height }
  public get left(): number { return this.x }
  public get top(): number { return this.y }
  public get right(): number { return this.x + this.width }
  public get bottom(): number { return this.y + this.height }
  public get area(): number { return this.width * this.height }
  public get topLeft(): Point { return new Point(this.left, this.top) }
  public get topRight(): Point { return new Point(this.right, this.top) }
  public get bottomLeft(): Point { return new Point(this.left, this.bottom) }
  public get bottomRight(): Point { return new Point(this.right, this.bottom) }

  public round(): Box<BoxType> {
    const [x, y, width, height] = [this.x, this.y, this.width, this.height]
      .map(val => Math.round(val))
    return new Box({ x, y, width, height })
  }

  public floor(): Box<BoxType> {
    const [x, y, width, height] = [this.x, this.y, this.width, this.height]
      .map(val => Math.floor(val))
    return new Box({ x, y, width, height })
  }

  public toSquare(): Box<BoxType> {
    let { x, y, width, height } = this
    const diff = Math.abs(width - height)
    if (width < height) {
      x -= (diff / 2)
      width += diff
    }
    if (height < width) {
      y -= (diff / 2)
      height += diff
    }

    return new Box({ x, y, width, height })
  }

  public rescale(s: IDimensions | number): Box<BoxType> {
    const scaleX = isDimensions(s) ? (s as IDimensions).width : s as number
    const scaleY = isDimensions(s) ? (s as IDimensions).height : s as number
    return new Box({
      x: this.x * scaleX,
      y: this.y * scaleY,
      width: this.width * scaleX,
      height: this.height * scaleY
    })
  }

  public pad(padX: number, padY: number): Box<BoxType> {
    let [x, y, width, height] = [
      this.x - (padX / 2),
      this.y - (padY / 2),
      this.width + padX,
      this.height + padY
    ]
    return new Box({ x, y, width, height })
  }

  public clipAtImageBorders(imgWidth: number, imgHeight: number): Box<BoxType> {
    const { x, y, right, bottom } = this
    const clippedX = Math.max(x, 0)
    const clippedY = Math.max(y, 0)

    const newWidth = right - clippedX
    const newHeight = bottom - clippedY
    const clippedWidth = Math.min(newWidth, imgWidth - clippedX)
    const clippedHeight = Math.min(newHeight, imgHeight - clippedY)

    return (new Box({ x: clippedX, y: clippedY, width: clippedWidth, height: clippedHeight})).floor()
  }

  public shift(sx: number, sy: number): Box<BoxType> {
    const { width, height } = this
    const x = this.x + sx
    const y = this.y + sy

    return new Box({ x, y, width, height })
  }

  public padAtBorders(imageHeight: number, imageWidth: number) {
    const w = this.width + 1
    const h = this.height + 1

    let dx = 1
    let dy = 1
    let edx = w
    let edy = h

    let x = this.left
    let y = this.top
    let ex = this.right
    let ey = this.bottom

    if (ex > imageWidth) {
      edx = -ex + imageWidth + w
      ex = imageWidth
    }
    if (ey > imageHeight) {
      edy = -ey + imageHeight + h
      ey = imageHeight
    }
    if (x < 1) {
      edy = 2 - x
      x = 1
    }
    if (y < 1) {
      edy = 2 - y
      y = 1
    }

    return { dy, edy, dx, edx, y, ey, x, ex, w, h }
  }

  public calibrate(region: Box) {
    return new Box({
      left: this.left + (region.left * this.width),
      top: this.top + (region.top * this.height),
      right: this.right + (region.right * this.width),
      bottom: this.bottom + (region.bottom * this.height)
    }).toSquare().round()
  }
}