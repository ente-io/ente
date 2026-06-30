import {
    playableVideoURLWeb,
    renderableImageBlobWeb,
} from "ente-gallery/services/convert-core";
import type { EnteFile } from "ente-media/file";
import { convertToMP4 } from "./ffmpeg";

export const renderableImageBlob = async (
    imageBlob: Blob,
    fileName: string,
): Promise<Blob> => renderableImageBlobWeb(imageBlob, fileName);

export const playableVideoURL = async (
    _file: EnteFile,
    videoFileName: string,
    videoBlob: Blob,
): Promise<string> =>
    playableVideoURLWeb(videoFileName, videoBlob, { convertToMP4 });
