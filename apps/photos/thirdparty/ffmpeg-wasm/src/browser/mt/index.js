/* eslint-disable no-undef */
const parseArgs = require('../../utils/parseArgs');

const getCore = (opts) => (
  createFFmpegCore(opts)
);

const ffmpeg = ({ Core, args }) => (
  Core.ccall(
    'emscripten_proxy_main',
    'number',
    ['number', 'number'],
    parseArgs(Core, args),
  )
);

module.exports = {
  getCore,
  ffmpeg,
};
