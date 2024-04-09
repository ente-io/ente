import { getFileNameSize } from "@/next/file";
import log from "@/next/log";
import { addLogLine } from "@ente/shared/logging";
import { NULL_EXTRACTED_METADATA } from "constants/upload";
import * as ffmpegService from "services/ffmpeg/ffmpegService";
import { ElectronFile } from "types/upload";

export async function getVideoMetadata(file: File | ElectronFile) {
    let videoMetadata = NULL_EXTRACTED_METADATA;
    try {
        addLogLine(`getVideoMetadata called for ${getFileNameSize(file)}`);
        videoMetadata = await ffmpegService.extractVideoMetadata(file);
        addLogLine(
            `videoMetadata successfully extracted ${getFileNameSize(file)}`,
        );
    } catch (e) {
        log.error("failed to get video metadata", e);
        addLogLine(
            `videoMetadata extracted failed ${getFileNameSize(file)} ,${
                e.message
            } `,
        );
    }

    return videoMetadata;
}
