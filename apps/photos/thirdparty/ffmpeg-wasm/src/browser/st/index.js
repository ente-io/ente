const parseArgs = require('../../utils/parseArgs');

const getCore = (opts) => (
  createFFmpegCore(opts)
);
const ffmpeg = ({ Core, args }) => (
  Core.ccall(
    'main',
    'number',
    ['number', 'number'],
    parseArgs(Core, args),
  )
);

module.exports = {
  getCore, ffmpeg,
};
