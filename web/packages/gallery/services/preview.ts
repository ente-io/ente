import type { EnteFile } from "@/media/file";
import { FileType } from "@/media/file-type";
import { downloadManager } from "./download";
import { generateVideoPreviewVariantWeb } from "./ffmpeg";

/**
 * Create a preview variant of the given video {@link file}.
 *
 * [Note: Preview variant of videos]
 *
 * A preview variant of a video is created by transcoding it into a smaller,
 * streamable and more standard format.
 *
 * The video is transcoded into a format that is both smaller but is also using
 * a much more widely supported codec etc so that it can be played back readily
 * across browsers and OSes independent of the codec used by the source video.
 *
 * We also use a format that can be streamed back by the client instead of
 * needing to download it all at once.
 *
 * @param file The {@link EnteFile} of type video for which we want to create a
 * preview variant.
 */
export const createVideoPreviewVariant = async (file: EnteFile) => {
    if (file.metadata.fileType != FileType.video)
        throw new Error("Preview variant can only be created for video files");

    const fileBlob = await downloadManager.fileBlob(file);
    const previewFileData = await generateVideoPreviewVariantWeb(fileBlob);
    // Unrevoked currently.
    const previewFileURL = URL.createObjectURL(new Blob([previewFileData]));
    return previewFileURL;
};
