import { isTensor } from '../utils';
import { ParamMapping } from './types';

export function extractWeightEntryFactory(weightMap: any, paramMappings: ParamMapping[]) {

  return function<T> (originalPath: string, paramRank: number, mappedPath?: string): T {
    const tensor = weightMap[originalPath]

    if (!isTensor(tensor, paramRank)) {
      throw new Error(`expected weightMap[${originalPath}] to be a Tensor${paramRank}D, instead have ${tensor}`)
    }

    paramMappings.push(
      { originalPath, paramPath: mappedPath || originalPath }
    )

    return tensor
  }

}
