/* eslint-disable no-undef */
const { log } = require('../utils/log');
const { CREATE_FFMPEG_CORE_IS_NOT_DEFINED } = require('../utils/errors');

/*
 * Fetch data from remote URL and convert to blob URL
 * to avoid CORS issue
 */
// const toBlobURL = async (url, mimeType) => {
//   log('info', `fetch ${url}`);
//   const buf = await (await fetch(url)).arrayBuffer();
//   log('info', `${url} file size = ${buf.byteLength} bytes`);
//   const blob = new Blob([buf], { type: mimeType });
//   const blobURL = URL.createObjectURL(blob);
//   log('info', `${url} blob URL = ${blobURL}`);
//   return blobURL;
// };

module.exports = async ({ corePath: _corePath, mt: _mt, runningInWorker: _runningInWorker }) => {
  if (typeof _corePath !== 'string') {
    throw Error('corePath should be a string!');
  }
  // const corePath = await toBlobURL(
  //   coreRemotePath,
  //   'application/javascript',
  // );
  // const wasmPath = await toBlobURL(
  //   coreRemotePath.replace('ffmpeg-core.js', 'ffmpeg-core.wasm'),
  //   'application/wasm',
  // );
  // const workerPath = await toBlobURL(
  //   coreRemotePath.replace('ffmpeg-core.js', 'ffmpeg-core.worker.js'),
  //   'application/javascript',
  // );
  const coreRemotePath = _corePath;
  const corePath = coreRemotePath;
  const wasmPath = coreRemotePath.replace(
    'ffmpeg-core.js',
    'ffmpeg-core.wasm',
  );
  let workerPath = null;
  if (_mt) {
    workerPath = coreRemotePath.replace(
      'ffmpeg-core.js',
      'ffmpeg-core.worker.js',
    );
  }
  if (typeof createFFmpegCore === 'undefined') {
    return new Promise((resolve) => {
      if (_runningInWorker) {
        importScripts(coreRemotePath);
      } else {
        const script = document.createElement('script');
        const eventHandler = () => {
          script.removeEventListener('load', eventHandler);
          if (typeof createFFmpegCore === 'undefined') {
            throw CREATE_FFMPEG_CORE_IS_NOT_DEFINED(coreRemotePath);
          }
          log('info', 'ffmpeg-core.js script loaded');
        };
        script.src = corePath;
        script.type = 'text/javascript';
        script.addEventListener('load', eventHandler);
        document.getElementsByTagName('head')[0].appendChild(script);
      }
      resolve({
        createFFmpegCore,
        corePath,
        wasmPath,
        workerPath,
      });
    });
  }
  log('info', 'ffmpeg-core.js script is loaded already');
  return Promise.resolve({
    createFFmpegCore,
    corePath,
    wasmPath,
    workerPath,
  });
};
