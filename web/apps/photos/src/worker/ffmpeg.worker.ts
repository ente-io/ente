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

export class DedicatedFFmpegWorker {
    private ffmpeg: FFmpeg;
    private ffmpegTaskQueue = new QueueProcessor<Uint8Array>();

    constructor() {
        this.ffmpeg = createFFmpeg({
            corePath: "/js/ffmpeg/ffmpeg-core.js",
            mt: false,
        });
    }

    /**
     * Execute a FFmpeg {@link command}.
     *
     * This is a sibling of {@link ffmpegExec} in ipc.ts exposed by the desktop
     * app. See [Note: FFmpeg in Electron].
     */
    async exec(
        command: string[],
        inputFile: File,
        outputFileName: string,
        timeoutMs,
    ): Promise<Uint8Array> {
        if (!this.ffmpeg.isLoaded()) await this.ffmpeg.load();

        const go = () =>
            ffmpegExec(this.ffmpeg, command, inputFile, outputFileName);

        const request = this.ffmpegTaskQueue.queueUpRequest(() =>
            timeoutMs ? withTimeout(go(), timeoutMs) : go(),
        );

        return await request.promise;
    }
}

expose(DedicatedFFmpegWorker, self);

const ffmpegExec = async (
    ffmpeg: FFmpeg,
    command: string[],
    inputFile: File,
    outputFileName: string,
) => {
    const [, extension] = nameAndExtension(inputFile.name);
    const tempNameSuffix = extension ? `input.${extension}` : "input";
    const tempInputFilePath = `${generateTempName(10, tempNameSuffix)}`;
    const tempOutputFilePath = `${generateTempName(10, outputFileName)}`;

    const cmd = substitutePlaceholders(
        command,
        tempInputFilePath,
        tempOutputFilePath,
    );

    try {
        ffmpeg.FS(
            "writeFile",
            tempInputFilePath,
            new Uint8Array(await inputFile.arrayBuffer()),
        );

        log.info(`Running FFmpeg (wasm) command ${cmd}`);
        await ffmpeg.run(...cmd);

        return ffmpeg.FS("readFile", tempOutputFilePath);
    } finally {
        try {
            ffmpeg.FS("unlink", tempInputFilePath);
        } catch (e) {
            log.error("Failed to remove input ${tempInputFilePath}", e);
        }
        try {
            ffmpeg.FS("unlink", tempOutputFilePath);
        } catch (e) {
            log.error("Failed to remove output ${tempOutputFilePath}", e);
        }
    }
};

const substitutePlaceholders = (
    command: string[],
    inputFilePath: string,
    outputFilePath: string,
) =>
    command.map((segment) => {
        if (segment == ffmpegPathPlaceholder) {
            return "";
        } else if (segment == inputPathPlaceholder) {
            return inputFilePath;
        } else if (segment == outputPathPlaceholder) {
            return outputFilePath;
        } else {
            return segment;
        }
    });
