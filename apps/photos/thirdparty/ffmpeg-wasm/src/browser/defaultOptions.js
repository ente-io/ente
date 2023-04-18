const { devDependencies } = require('../../package.json');

/*
 * Default options for browser environment
 */
module.exports = {
  corePath: typeof process !== 'undefined' && process.env.NODE_ENV === 'development'
    ? '/node_modules/@ffmpeg/core/dist/ffmpeg-core.js'
    : `https://unpkg.com/@ffmpeg/core@${devDependencies['@ffmpeg/core'].substring(1)}/dist/ffmpeg-core.js`,
};
