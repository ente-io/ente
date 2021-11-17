import { isValidProbablitiy } from '../utils';
import { IBoundingBox } from './BoundingBox';
import { LabeledBox } from './LabeledBox';
import { IRect } from './Rect';

export class PredictedBox extends LabeledBox {

  public static assertIsValidPredictedBox(box: any, callee: string) {
    LabeledBox.assertIsValidLabeledBox(box, callee)

    if (
      !isValidProbablitiy(box.score)
      || !isValidProbablitiy(box.classScore)
    ) {
      throw new Error(`${callee} - expected properties score (${box.score}) and (${box.classScore}) to be a number between [0, 1]`)
    }
  }

  private _score: number
  private _classScore: number

  constructor(box: IBoundingBox | IRect | any, label: number, score: number, classScore: number) {
    super(box, label)
    this._score = score
    this._classScore = classScore
  }

  public get score(): number { return this._score }
  public get classScore(): number { return this._classScore }

}