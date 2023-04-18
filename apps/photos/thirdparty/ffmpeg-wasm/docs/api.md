# API

- [createFFmpeg()](#create-ffmpeg)
  - [ffmpeg.load()](#ffmpeg-load)
  - [ffmpeg.run()](#ffmpeg-run)
  - [ffmpeg.FS()](#ffmpeg-fs)
  - [ffmpeg.exit()](#ffmpeg-exit)
  - [ffmpeg.setLogging()](#ffmpeg-setlogging)
  - [ffmpeg.setLogger()](#ffmpeg-setlogger)
  - [ffmpeg.setProgress()](#ffmpeg-setProgress)
- [fetchFile()](#fetch-file)

---

<a name="create-ffmpeg"></a>

## createFFmpeg(options): ffmpeg

createFFmpeg is a factory function that creates a ffmpeg instance.

**Arguments:**

- `options` an object of customized options
  - `corePath` path for ffmpeg-core.js script
  - `log` a boolean to turn on all logs, default is `false`
  - `logger` a function to get log messages, a quick example is `({ message }) => console.log(message)`
  - `progress` a function to trace the progress, a quick example is `p => console.log(p)`

**Examples:**

```javascript
const { createFFmpeg } = FFmpeg;
const ffmpeg = createFFmpeg({
  corePath: "./node_modules/@ffmpeg/core/dist/ffmpeg-core.js",
  log: true,
});
```

<a name="ffmpeg-load"></a>

### ffmpeg.load(): Promise

Load ffmpeg.wasm-core script.

In browser environment, the ffmpeg.wasm-core script is fetch from CDN and can be assign to a local path by assigning `corePath`. In node environment, we use dynamic require and the default `corePath` is `$ffmpeg/core`.

Typically the load() func might take few seconds to minutes to complete, better to do it as early as possible.

**Examples:**

```javascript
(async () => {
  await ffmpeg.load();
})();
```

<a name="ffmpeg-run"></a>

### ffmpeg.run(...args): Promise

This is the major function in ffmpeg.wasm, you can just imagine it as ffmpeg native cli and what you need to pass is the same.

**Arguments:**

- `args` string arguments just like cli tool.

**Examples:**

```javascript
(async () => {
  await ffmpeg.run('-i', 'flame.avi', '-s', '1920x1080', 'output.mp4');
  /* equals to `$ ffmpeg -i flame.avi -s 1920x1080 output.mp4` */
})();
```

<a name="ffmpeg-fs"></a>

### ffmpeg.FS(method, ...args): any

Run FS operations.

For input/output file of ffmpeg.wasm, it is required to save them to MEMFS first so that ffmpeg.wasm is able to consume them. Here we rely on the FS methods provided by Emscripten.

For more info, check https://emscripten.org/docs/api_reference/Filesystem-API.html

**Arguments:**

- `method` string method name
- `args` arguments to pass to method

**Examples:**

```javascript
/* Write data to MEMFS, need to use Uint8Array for binary data */
ffmpeg.FS('writeFile', 'video.avi', new Uint8Array(...));
/* Read data from MEMFS */
ffmpeg.FS('readFile', 'video.mp4');
/* Delete file in MEMFS */
ffmpeg.FS('unlink', 'video.mp4');
```

<a name="ffmpeg-exit"></a>

### ffmpeg.exit()

Kill the execution of the program, also remove MEMFS to free memory

**Examples:**

```javascript
const ffmpeg = createFFmpeg({ log: true });
await ffmpeg.load(...);
setTimeout(() => {
  ffmpeg.exit(); // ffmpeg.exit() is callable only after load() stage.
}, 1000);
await ffmpeg.run(...);
```

<a name="ffmpeg-setlogging"></a>

### ffmpeg.setLogging(logging)

Control whether to output log information to console

**Arguments**

- `logging` a boolean to turn of/off log messages in console

**Examples:**

```javascript
ffmpeg.setLogging(true);
```

<a name="ffmpeg-setlogger"></a>

### ffmpeg.setLogger(logger)

Set customer logger to get ffmpeg.wasm output messages.

**Arguments**

- `logger` a function to handle the messages

**Examples:**

```javascript
ffmpeg.setLogger(({ type, message }) => {
  console.log(type, message);
  /*
   * type can be one of following:
   *
   * info: internal workflow debug messages
   * fferr: ffmpeg native stderr output
   * ffout: ffmpeg native stdout output
   */
});
```

<a name="ffmpeg-setprogress"></a>

### ffmpeg.setProgress(progress)

Progress handler to get current progress of ffmpeg command.

**Arguments**

- `progress` a function to handle progress info

**Examples:**

```javascript

ffmpeg.setProgress(({ ratio }) => {
  console.log(ratio);
  /*
   * ratio is a float number between 0 to 1.
   */
});
```

<a name="fetch-file"></a>

### fetchFile(media): Promise
   
Helper function for fetching files from various resource.

Sometimes the video/audio file you want to process may located in a remote URL and somewhere in your local file system.
   
This helper function helps you to fetch to file and return an Uint8Array variable for ffmpeg.wasm to consume.

**Arguments**

- `media` an URL string, base64 string or File, Blob, Buffer object

**Examples:**

```javascript
(async () => {
  const data = await fetchFile('https://github.com/ffmpegwasm/testdata/raw/master/video-3s.avi');
  /*
   * data will be in Uint8Array format
   */
})();
```
