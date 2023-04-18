export const FS: {
    writeFile: (fileName: string, binaryData: Uint8Array) => void,
    readFile: (fileName: string) => Uint8Array,
    unlink: (fileName: string) => void,
};

type FSMethodNames = { [K in keyof typeof FS]: (typeof FS)[K] extends (...args: any[]) => any ? K : never }[keyof typeof FS];
type FSMethodArgs = { [K in FSMethodNames]: Parameters<(typeof FS)[K]> };
type FSMethodReturn = { [K in FSMethodNames]: ReturnType<(typeof FS)[K]> };

type LogCallback = (logParams: { type: string; message: string }) => any;
type ProgressCallback = (progressParams: { ratio: number }) => any;

export interface CreateFFmpegOptions {
    /** path for ffmpeg-core.js script */
    corePath?: string;
    /** a boolean to turn on all logs, default is false */
    log?: boolean;
    /** a boolean to specify if the core is single or multi-threaded */
    mt?:boolean
    /** a function to get log messages, a quick example is ({ message }) => console.log(message) */
    logger?: LogCallback;
    /** a function to trace the progress, a quick example is p => console.log(p) */
    progress?: ProgressCallback;
}

export interface FFmpeg {
    /*
     * Load ffmpeg.wasm-core script.
     * In browser environment, the ffmpeg.wasm-core script is fetch from
     * CDN and can be assign to a local path by assigning `corePath`.
     * In node environment, we use dynamic require and the default `corePath`
     * is `$ffmpeg/core`.
     *
     * Typically the load() func might take few seconds to minutes to complete,
     * better to do it as early as possible.
     *
     */
    load(): Promise<void>;
    /*
     * Determine whether the Core is loaded.
     */
    isLoaded(): boolean;
    /*
     * Run ffmpeg command.
     * This is the major function in ffmpeg.wasm, you can just imagine it
     * as ffmpeg native cli and what you need to pass is the same.
     *
     * For example, you can convert native command below:
     *
     * ```
     * $ ffmpeg -i video.avi -c:v libx264 video.mp4
     * ```
     *
     * To
     *
     * ```
     * await ffmpeg.run('-i', 'video.avi', '-c:v', 'libx264', 'video.mp4');
     * ```
     *
     */
    run(...args: string[]): Promise<void>;
    /*
     * Run FS operations.
     * For input/output file of ffmpeg.wasm, it is required to save them to MEMFS
     * first so that ffmpeg.wasm is able to consume them. Here we rely on the FS
     * methods provided by Emscripten.
     *
     * Common methods to use are:
     * ffmpeg.FS('writeFile', 'video.avi', new Uint8Array(...)): writeFile writes
     * data to MEMFS. You need to use Uint8Array for binary data.
     * ffmpeg.FS('readFile', 'video.mp4'): readFile from MEMFS.
     * ffmpeg.FS('unlink', 'video.map'): delete file from MEMFS.
     *
     * For more info, check https://emscripten.org/docs/api_reference/Filesystem-API.html
     *
     */
    FS<Method extends FSMethodNames>(method: Method, ...args: FSMethodArgs[Method]): FSMethodReturn[Method];
    setProgress(progress: ProgressCallback): void;
    setLogger(log: LogCallback): void;
    setLogging(logging: boolean): void;
    exit(): void;
}

/*
 * Create ffmpeg instance.
 * Each ffmpeg instance owns an isolated MEMFS and works
 * independently.
 *
 * For example:
 *
 * ```
 * const ffmpeg = createFFmpeg({
 *  log: true,
 *  logger: () => {},
 *  progress: () => {},
 *  corePath: '',
 * })
 * ```
 *
 * For the usage of these four arguments, check config.js
 *
 */
export function createFFmpeg(options?: CreateFFmpegOptions): FFmpeg;
/*
 * Helper function for fetching files from various resource.
 * Sometimes the video/audio file you want to process may located
 * in a remote URL and somewhere in your local file system.
 *
 * This helper function helps you to fetch to file and return an
 * Uint8Array variable for ffmpeg.wasm to consume.
 *
 */
export function fetchFile(data: string | Buffer | Blob | File): Promise<Uint8Array>;
