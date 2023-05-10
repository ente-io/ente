export interface IPoint {
  x: number
  y: number
}

export class Point implements IPoint {
  public x: number
  public y: number

  constructor(x: number, y: number) {
    this.x = x
    this.y = y
  }

  // get x(): number { return this._x }
  // get y(): number { return this._y }

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

  public round(): Point {
    return new Point(Math.round(this.x), Math.round(this.y))
  }

  public bound(lower: number, higher: number): Point {
    const x = Math.max(lower, Math.min(higher, this.x));
    const y = Math.max(lower, Math.min(higher, this.y));
    return new Point(x, y);
  }
}