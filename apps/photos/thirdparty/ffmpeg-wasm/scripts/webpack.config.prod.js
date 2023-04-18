const path = require('path');
const common = require('./webpack.config.common');

const genConfig = ({
  entry, filename, library, libraryTarget,
}) => ({
  ...common,
  mode: 'production',
  devtool: 'source-map',
  entry,
  output: {
    path: path.resolve(__dirname, '..', 'dist'),
    filename,
    library,
    libraryTarget,
  },
});

module.exports = [
  genConfig({
    entry: path.resolve(__dirname, '..', 'src', 'index.js'),
    filename: 'ffmpeg.min.js',
    library: 'FFmpeg',
    libraryTarget: 'umd',
  }),
];
