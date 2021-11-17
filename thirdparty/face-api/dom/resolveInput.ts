import { env } from '../env';

export function resolveInput(arg: string | any) {
  if (!env.isNodejs() && typeof arg === 'string') {
    return document.getElementById(arg)
  }
  return arg
}