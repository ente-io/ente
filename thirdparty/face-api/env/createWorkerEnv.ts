import { fetch as tfFetch } from '@tensorflow/tfjs-core/dist/util';
import { Environment } from './types';

export function createWorkerEnv(): Environment {

  const fetch = tfFetch || function() {
    throw new Error('fetch - missing fetch implementation for browser environment')
  }

  const readFile = function() {
    throw new Error('readFile - filesystem not available for browser environment')
  }

  const createCanvasElement = function() {
    const canvas = new OffscreenCanvas(1, 1) as any;
    canvas.localName = 'canvas';
    canvas.nodeName = 'CANVAS';
    canvas.tagName = 'CANVAS';
    canvas.nodeType = 1;
    canvas.innerHTML = '';
    canvas.remove = () => {
        console.log('nope');
    };
    return canvas;
  }

  const HTMLImageElement = function() {}
  const HTMLVideoElement = function() {}

  return {
    Canvas: OffscreenCanvas as any,
    CanvasRenderingContext2D: OffscreenCanvasRenderingContext2D as any,
    Image: HTMLImageElement as any,
    ImageData: ImageData,
    Video: HTMLVideoElement as any,
    createCanvasElement: createCanvasElement,
    createImageElement: () => document.createElement('img'),
    fetch,
    readFile
  }
}