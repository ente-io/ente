const fs = require('fs');
const { createFFmpeg, fetchFile } = require('../../src');

const ffmpeg = createFFmpeg({ log: true });

(async () => {
  await ffmpeg.load();
  ffmpeg.FS('writeFile', 'flame.avi', await fetchFile('../assets/flame.avi'));
  await ffmpeg.run('-i', 'flame.avi', '-ss', '0', '-to', '1', 'flame_trim.avi');
  await fs.promises.writeFile('flame_trim.avi', ffmpeg.FS('readFile', 'flame_trim.avi'));
  process.exit(0);
})();
