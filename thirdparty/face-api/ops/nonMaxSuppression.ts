import { Box } from '../classes/Box';
import { iou } from './iou';

export function nonMaxSuppression(
  boxes: Box[],
  scores: number[],
  iouThreshold: number,
  isIOU: boolean = true
): number[] {

  let indicesSortedByScore = scores
    .map((score, boxIndex) => ({ score, boxIndex }))
    .sort((c1, c2) => c1.score - c2.score)
    .map(c => c.boxIndex)

  const pick: number[] = []

  while(indicesSortedByScore.length > 0) {
    const curr = indicesSortedByScore.pop() as number
    pick.push(curr)

    const indices = indicesSortedByScore

    const outputs: number[] = []
    for (let i = 0; i < indices.length; i++) {
      const idx = indices[i]

      const currBox = boxes[curr]
      const idxBox = boxes[idx]

      outputs.push(iou(currBox, idxBox, isIOU))
    }

    indicesSortedByScore = indicesSortedByScore.filter(
      (_, j) => outputs[j] <= iouThreshold
    )
  }

  return pick

}