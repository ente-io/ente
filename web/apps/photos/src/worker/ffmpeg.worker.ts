import { nameAndExtension } from "@/next/file";
import log from "@/next/log";
import { withTimeout } from "@ente/shared/utils";
import QueueProcessor from "@ente/shared/utils/queueProcessor";
import { generateTempName } from "@ente/shared/utils/temp";
import { expose } from "comlink";
import {
    ffmpegPathPlaceholder,
    inputPathPlaceholder,
    outputPathPlaceholder,
} from "constants/ffmpeg";
import { FFmpeg, createFFmpeg } from "ffmpeg-wasm";
import { getUint8ArrayView } from "services/readerService";

export class DedicatedFFmpegWorker {
    private wasmFFmpeg: WasmFFmpeg;

    constructor() {
        this.wasmFFmpeg = new WasmFFmpeg();
    }

    /**
     * Execute a ffmpeg {@link command}.
     *
     * This is a sibling of {@link ffmpegExec} in ipc.ts exposed by the desktop
     * app. See [Note: ffmpeg in Electron].
     */
    run(cmd, inputFile, outputFileName, timeoutMS) {
        return this.wasmFFmpeg.run(cmd, inputFile, outputFileName, timeoutMS);
    }
}

expose(DedicatedFFmpegWorker, self);

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
        timeoutMS,
    ) {
        const exec = () => this.execute(cmd, inputFile, outputFileName);
        const request = this.ffmpegTaskQueue.queueUpRequest(() =>
            timeoutMS ? withTimeout<File>(exec(), timeoutMS) : exec(),
        );
        return await request.promise;
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
                if (cmdPart === ffmpegPathPlaceholder) {
                    return "";
                } else if (cmdPart === inputPathPlaceholder) {
                    return tempInputFilePath;
                } else if (cmdPart === outputPathPlaceholder) {
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
