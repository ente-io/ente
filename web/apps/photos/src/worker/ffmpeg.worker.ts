import { nameAndExtension } from "@/next/file";
import log from "@/next/log";
import { withTimeout } from "@ente/shared/utils";
import QueueProcessor from "@ente/shared/utils/queueProcessor";
import { generateTempName } from "@ente/shared/utils/temp";
import * as Comlink from "comlink";
import {
    FFMPEG_PLACEHOLDER,
    INPUT_PATH_PLACEHOLDER,
    OUTPUT_PATH_PLACEHOLDER,
} from "constants/ffmpeg";
import { FFmpeg, createFFmpeg } from "ffmpeg-wasm";
import { getUint8ArrayView } from "services/readerService";

export class DedicatedFFmpegWorker {
    wasmFFmpeg: WasmFFmpeg;
    constructor() {
        this.wasmFFmpeg = new WasmFFmpeg();
    }

    run(cmd, inputFile, outputFileName, dontTimeout) {
        return this.wasmFFmpeg.run(cmd, inputFile, outputFileName, dontTimeout);
    }
}

Comlink.expose(DedicatedFFmpegWorker, self);

const FFMPEG_EXECUTION_WAIT_TIME = 30 * 1000;

export class WasmFFmpeg {
    private ffmpeg: FFmpeg;
    private ready: Promise<void> = null;
    private ffmpegTaskQueue = new QueueProcessor<File>();

    constructor() {
        this.ffmpeg = createFFmpeg({
            corePath: "/js/ffmpeg/ffmpeg-core.js",
            mt: false,
        });

        this.ready = this.init();
    }

    private async init() {
        if (!this.ffmpeg.isLoaded()) {
            await this.ffmpeg.load();
        }
    }

    async run(
        cmd: string[],
        inputFile: File,
        outputFileName: string,
        dontTimeout = false,
    ) {
        const response = this.ffmpegTaskQueue.queueUpRequest(() => {
            if (dontTimeout) {
                return this.execute(cmd, inputFile, outputFileName);
            } else {
                return withTimeout<File>(
                    this.execute(cmd, inputFile, outputFileName),
                    FFMPEG_EXECUTION_WAIT_TIME,
                );
            }
        });
        try {
            return await response.promise;
        } catch (e) {
            log.error("ffmpeg run failed", e);
            throw e;
        }
    }

    private async execute(
        cmd: string[],
        inputFile: File,
        outputFileName: string,
    ) {
        let tempInputFilePath: string;
        let tempOutputFilePath: string;
        try {
            await this.ready;
            const [, extension] = nameAndExtension(inputFile.name);
            const tempNameSuffix = extension ? `input.${extension}` : "input";
            tempInputFilePath = `${generateTempName(10, tempNameSuffix)}`;
            this.ffmpeg.FS(
                "writeFile",
                tempInputFilePath,
                await getUint8ArrayView(inputFile),
            );
            tempOutputFilePath = `${generateTempName(10, outputFileName)}`;

            cmd = cmd.map((cmdPart) => {
                if (cmdPart === FFMPEG_PLACEHOLDER) {
                    return "";
                } else if (cmdPart === INPUT_PATH_PLACEHOLDER) {
                    return tempInputFilePath;
                } else if (cmdPart === OUTPUT_PATH_PLACEHOLDER) {
                    return tempOutputFilePath;
                } else {
                    return cmdPart;
                }
            });
            log.info(`${cmd}`);
            await this.ffmpeg.run(...cmd);
            return new File(
                [this.ffmpeg.FS("readFile", tempOutputFilePath)],
                outputFileName,
            );
        } finally {
            try {
                this.ffmpeg.FS("unlink", tempInputFilePath);
            } catch (e) {
                log.error("unlink input file failed", e);
            }
            try {
                this.ffmpeg.FS("unlink", tempOutputFilePath);
            } catch (e) {
                log.error("unlink output file failed", e);
            }
        }
    }
}
