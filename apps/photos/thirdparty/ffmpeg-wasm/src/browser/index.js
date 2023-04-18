const defaultOptions = require('./defaultOptions');
const getCreateFFmpegCore = require('./getCreateFFmpegCore');
const fetchFile = require('./fetchFile');
const { getCore: getCoreMT, ffmpeg: ffmpegMT } = require('./mt');
const { getCore: getCoreST, ffmpeg: ffmpegST } = require('./st');

module.exports = {
  defaultOptions,
  getCreateFFmpegCore,
  fetchFile,
  getCore: (mt) => (mt ? getCoreMT : getCoreST),
  ffmpeg: (mt) => (mt ? ffmpegMT : ffmpegST)
};
