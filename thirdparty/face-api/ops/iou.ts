import { Box } from '../classes/Box';

export function iou(box1: Box, box2: Box, isIOU: boolean = true) {
  const width = Math.max(0.0, Math.min(box1.right, box2.right) - Math.max(box1.left, box2.left))
  const height = Math.max(0.0, Math.min(box1.bottom, box2.bottom) - Math.max(box1.top, box2.top))
  const interSection = width * height

  return isIOU
    ? interSection / (box1.area + box2.area - interSection)
    : interSection / Math.min(box1.area, box2.area)
}