import { createFFmpeg, FFmpeg } from 'ffmpeg-wasm';
import QueueProcessor from 'services/queueProcessor';
import { getUint8ArrayView } from 'services/readerService';
import { promiseWithTimeout } from 'utils/common';
import { CustomError } from 'utils/error';

import { logError } from 'utils/sentry';
import { generateTempName } from 'utils/temp';

const INPUT_PATH_PLACEHOLDER = 'INPUT';
const FFMPEG_PLACEHOLDER = 'FFMPEG';
const OUTPUT_PATH_PLACEHOLDER = 'OUTPUT';

const FFMPEG_EXECUTION_WAIT_TIME = 30 * 1000;

export class WasmFFmpeg {
    private ffmpeg: FFmpeg;
    private ready: Promise<void> = null;
    private ffmpegTaskQueue = new QueueProcessor<any>(1);

    constructor() {
        this.ffmpeg = createFFmpeg({
            corePath: '/js/ffmpeg/ffmpeg-core.js',
            mt: false,
        });

        this.ready = this.init();
    }

    private async init() {
        if (!this.ffmpeg.isLoaded()) {
            await this.ffmpeg.load();
        }
    }

    async run(cmd: string[], inputFile: File, outputFileName: string) {
        const response = this.ffmpegTaskQueue.queueUpRequest(() =>
            promiseWithTimeout(
                this.execute(cmd, inputFile, outputFileName),
                FFMPEG_EXECUTION_WAIT_TIME
            )
        );
        try {
            return await response.promise;
        } catch (e) {
            if (e.message === CustomError.REQUEST_CANCELLED) {
                // ignore
                return null;
            } else {
                logError(e, 'ffmpeg thumbnail generation failed');
                throw e;
            }
        }
    }

    private async execute(
        cmd: string[],
        inputFile: File,
        outputFileName: string
    ) {
        let tempInputFilePath: string;
        let tempOutputFilePath: string;
        try {
            await this.ready;
            tempInputFilePath = `${generateTempName(10)}- ${inputFile.name}`;
            this.ffmpeg.FS(
                'writeFile',
                tempInputFilePath,
                await getUint8ArrayView(inputFile)
            );
            tempOutputFilePath = `${generateTempName(10)}-${outputFileName}`;

            cmd.map((cmdPart) => {
                if (cmdPart === FFMPEG_PLACEHOLDER) {
                    return '';
                } else if (cmdPart === INPUT_PATH_PLACEHOLDER) {
                    return tempInputFilePath;
                } else if (cmdPart === OUTPUT_PATH_PLACEHOLDER) {
                    return tempOutputFilePath;
                } else {
                    return cmdPart;
                }
            });
            await this.ffmpeg.run(...cmd);
            return this.ffmpeg.FS('readFile', tempOutputFilePath);
        } finally {
            try {
                this.ffmpeg.FS('unlink', tempInputFilePath);
            } catch (e) {
                logError(e, 'unlink input file failed');
            }
            try {
                this.ffmpeg.FS('unlink', tempOutputFilePath);
            } catch (e) {
                logError(e, 'unlink output file failed');
            }
        }
    }
}
