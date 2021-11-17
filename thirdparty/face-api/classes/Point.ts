export interface IPoint {
  x: number
  y: number
}

export class Point implements IPoint {
  private _x: number
  private _y: number

  constructor(x: number, y: number) {
    this._x = x
    this._y = y
  }

  get x(): number { return this._x }
  get y(): number { return this._y }

  public add(pt: IPoint): Point {
    return new Point(this.x + pt.x, this.y + pt.y)
  }

  public sub(pt: IPoint): Point {
    return new Point(this.x - pt.x, this.y - pt.y)
  }

  public mul(pt: IPoint): Point {
    return new Point(this.x * pt.x, this.y * pt.y)
  }

  public div(pt: IPoint): Point {
    return new Point(this.x / pt.x, this.y / pt.y)
  }

  public abs(): Point {
    return new Point(Math.abs(this.x), Math.abs(this.y))
  }

  public magnitude(): number {
    return Math.sqrt(Math.pow(this.x, 2) + Math.pow(this.y, 2))
  }

  public floor(): Point {
    return new Point(Math.floor(this.x), Math.floor(this.y))
  }
}