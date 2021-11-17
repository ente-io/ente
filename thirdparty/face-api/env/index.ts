import { createBrowserEnv } from './createBrowserEnv';
import { createFileSystem } from './createFileSystem';
import { isBrowser } from './isBrowser';
import { isNodejs } from './isNodejs';
import { Environment } from './types';

let environment: Environment | null

function getEnv(): Environment {
  if (!environment) {
    throw new Error('getEnv - environment is not defined, check isNodejs() and isBrowser()')
  }
  return environment
}

function setEnv(env: Environment) {
  environment = env
}

function initialize() {
  // check for isBrowser() first to prevent electron renderer process
  // to be initialized with wrong environment due to isNodejs() returning true
  if (isBrowser()) {
    setEnv(createBrowserEnv())
  }
}

function monkeyPatch(env: Partial<Environment>) {
  if (!environment) {
    initialize()
  }

  if (!environment) {
    throw new Error('monkeyPatch - environment is not defined, check isNodejs() and isBrowser()')
  }

  const { Canvas = environment.Canvas, Image = environment.Image } = env
  environment.Canvas = Canvas
  environment.Image = Image
  environment.createCanvasElement = env.createCanvasElement || (() => new Canvas())
  environment.createImageElement = env.createImageElement || (() => new Image())

  environment.ImageData = env.ImageData || environment.ImageData
  environment.Video = env.Video || environment.Video
  environment.fetch = env.fetch || environment.fetch
  environment.readFile = env.readFile || environment.readFile
}

export const env = {
  getEnv,
  setEnv,
  initialize,
  createBrowserEnv,
  createFileSystem,
  monkeyPatch,
  isBrowser,
  isNodejs
}

initialize()

export * from './types'
