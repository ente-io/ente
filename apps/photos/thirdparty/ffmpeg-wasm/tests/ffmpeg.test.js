const { createFFmpeg } = FFmpeg;

describe('load()', () => {
  it('should throw error when corePath is not a string', async () => {
    const ffmpeg = createFFmpeg({ ...OPTIONS, corePath: null });

    try {
      await ffmpeg.load();
    } catch (e) {
      expect(e).to.be.an('Error');
    }
  });
  it('should throw error when not called before FS() and run()', () => {
    const ffmpeg = createFFmpeg(OPTIONS);
    expect(() => ffmpeg.FS('readdir', 'dummy')).to.throw();
    expect(() => ffmpeg.run('-h')).to.throw();
  });

  it('should throw error when running load() more than once', async () => {
    const ffmpeg = createFFmpeg(OPTIONS);
    await ffmpeg.load();
    try {
      await ffmpeg.load();
    } catch (e) {
      expect(e).to.be.an('Error');
    }
  }).timeout(TIMEOUT);
});

describe('isLoaded()', () => {
  it('should return true when loaded', async () => {
    const ffmpeg = createFFmpeg(OPTIONS);
    await ffmpeg.load();
    expect(ffmpeg.isLoaded()).to.equal(true);
  }).timeout(TIMEOUT);
});

describe('run()', () => {
  it('should not allow to run two command at the same time', async () => {
    const ffmpeg = createFFmpeg(OPTIONS);
    await ffmpeg.load();
    ffmpeg.run('-h');
    setTimeout(() => {
      try {
        ffmpeg.run('-h');
      } catch (e) {
        expect(e).to.be.an(Error);
      }
    }, 500);
  }).timeout(TIMEOUT);
});

describe('FS()', () => {
  const ffmpeg = createFFmpeg(OPTIONS);
  before(async function cb() {
    this.timeout(0);
    await ffmpeg.load();
  });

  it('should throw error when readdir for invalid path ', () => {
    expect(() => ffmpeg.FS('readdir', '/invalid')).to.throw(/readdir/);
  });
  it('should throw error when readFile for invalid path ', () => {
    expect(() => ffmpeg.FS('readFile', '/invalid')).to.throw(/readFile/);
  });
  it('should throw an default error ', () => {
    expect(() => ffmpeg.FS('unlink', '/invalid')).to.throw(/Oops/);
  });
});
