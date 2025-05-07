/**
 * @file A bridge to the ffmpeg utility process. This code runs in the main
 * process.
 */

import type { FFmpegUtilityProcess } from "./ffmpeg-worker";
import { ffmpegUtilityProcessPort } from "./workers";

/**
 * Return a handle to the ffmpeg utility process, starting it if needed.
 */
export const ffmpegUtilityProcess = () => {
    return ffmpegUtilityProcessPort() as unknown as FFmpegUtilityProcess;
};
