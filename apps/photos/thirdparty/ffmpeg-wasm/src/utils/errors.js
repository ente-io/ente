const NO_LOAD = Error(''.trim('\n'));

const CREATE_FFMPEG_CORE_IS_NOT_DEFINED = (corePath) => (Error(`
createFFmpegCore is not defined. ffmpeg.wasm is unable to find createFFmpegCore after loading ffmpeg-core.js from ${corePath}. Use another URL when calling createFFmpeg():

const ffmpeg = createFFmpeg({
  corePath: 'http://localhost:3000/ffmpeg-core.js',
});
`));

module.exports = {
  CREATE_FFMPEG_CORE_IS_NOT_DEFINED,
};
