import { ParamMapping } from './types';

export function disposeUnusedWeightTensors(weightMap: any, paramMappings: ParamMapping[]) {
  Object.keys(weightMap).forEach(path => {
    if (!paramMappings.some(pm => pm.originalPath === path)) {
      weightMap[path].dispose()
    }
  })
}
