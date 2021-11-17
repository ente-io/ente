import { isValidNumber } from '../utils';
import { IBoundingBox } from './BoundingBox';
import { Box } from './Box';
import { IRect } from './Rect';

export class LabeledBox extends Box<LabeledBox> {

  public static assertIsValidLabeledBox(box: any, callee: string) {
    Box.assertIsValidBox(box, callee)

    if (!isValidNumber(box.label)) {
      throw new Error(`${callee} - expected property label (${box.label}) to be a number`)
    }
  }

  private _label: number

  constructor(box: IBoundingBox | IRect | any, label: number) {
    super(box)
    this._label = label
  }

  public get label(): number { return this._label }

}