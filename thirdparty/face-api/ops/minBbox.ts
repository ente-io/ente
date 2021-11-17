import { BoundingBox, IPoint } from '../classes';

export function minBbox(pts: IPoint[]): BoundingBox {
  const xs = pts.map(pt => pt.x)
  const ys = pts.map(pt => pt.y)
  const minX = xs.reduce((min, x) => x < min ? x : min, Infinity)
  const minY = ys.reduce((min, y) => y < min ? y : min, Infinity)
  const maxX = xs.reduce((max, x) => max < x ? x : max, 0)
  const maxY = ys.reduce((max, y) => max < y ? y : max, 0)

  return new BoundingBox(minX, minY, maxX, maxY)
}
