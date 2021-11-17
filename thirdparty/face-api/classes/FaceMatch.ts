import { round } from '../utils';

export interface IFaceMatch {
  label: string
  distance: number
}

export class FaceMatch implements IFaceMatch {
  private _label: string
  private _distance: number

  constructor(label: string, distance: number) {
    this._label = label
    this._distance = distance
  }

  public get label(): string { return this._label }
  public get distance(): number { return this._distance }

  public toString(withDistance: boolean = true): string {
    return `${this.label}${withDistance ? ` (${round(this.distance)})` : ''}`
  }
}