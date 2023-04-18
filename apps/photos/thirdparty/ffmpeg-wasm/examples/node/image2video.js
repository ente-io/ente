const fs = require('fs');
const { createFFmpeg, fetchFile } = require('../../src');

const ffmpeg = createFFmpeg({ log: true });

(async () => {
  await ffmpeg.load();
  ffmpeg.FS('writeFile', 'audio.ogg', await fetchFile('../assets/triangle/audio.ogg'));
  for (let i = 0; i < 60; i += 1) {
    const num = `00${i}`.slice(-3);
    ffmpeg.FS('writeFile', `tmp.${num}.png`, await fetchFile(`../assets/triangle/tmp.${num}.png`));
  }
  console.log(ffmpeg.FS('readdir', '/'));
  await ffmpeg.run('-framerate', '30', '-pattern_type', 'glob', '-i', '*.png', '-i', 'audio.ogg', '-c:a', 'copy', '-shortest', '-c:v', 'libx264', '-pix_fmt', 'yuv420p', 'out.mp4');
  await ffmpeg.FS('unlink', 'audio.ogg');
  for (let i = 0; i < 60; i += 1) {
    const num = `00${i}`.slice(-3);
    await ffmpeg.FS('unlink', `tmp.${num}.png`);
  }
  await fs.promises.writeFile('out.mp4', ffmpeg.FS('readFile', 'out.mp4'));
  process.exit(0);
})();
