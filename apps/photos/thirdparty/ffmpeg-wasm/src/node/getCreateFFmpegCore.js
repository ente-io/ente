const { log } = require('../utils/log');

module.exports = ({ corePath }) => new Promise((resolve) => {
  log('info', `fetch ffmpeg.wasm-core script from ${corePath}`);
  // eslint-disable-next-line import/no-dynamic-require
  resolve({ createFFmpegCore: require(corePath) });
});
