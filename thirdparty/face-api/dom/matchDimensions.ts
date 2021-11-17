import { IDimensions } from '../classes';
import { getMediaDimensions } from './getMediaDimensions';

export function matchDimensions(input: IDimensions, reference: IDimensions, useMediaDimensions: boolean = false) {
  const { width, height } = useMediaDimensions
    ? getMediaDimensions(reference)
    : reference
  input.width = width
  input.height = height
  return { width, height }
}