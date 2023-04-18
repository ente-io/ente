const fs = require('fs');
const { createFFmpeg, fetchFile } = require('../../src');

const ffmpeg = createFFmpeg({ log: true });

(async () => {
  await ffmpeg.load();
  ffmpeg.FS('writeFile', 'flame.avi', await fetchFile('../assets/flame.avi'));
  await ffmpeg.run('-i', 'flame.avi', '-map', '0:v', '-r', '25', 'out_%06d.bmp');
  ffmpeg.FS('readdir', '/').filter((p) => p.endsWith('.bmp')).forEach(async (p) => {
    fs.writeFileSync(p, ffmpeg.FS('readFile', p));
  });
  process.exit(0);
})();
