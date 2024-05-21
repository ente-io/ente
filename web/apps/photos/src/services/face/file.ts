import { FILE_TYPE } from "@/media/file-type";
import { decodeLivePhoto } from "@/media/live-photo";
import DownloadManager from "services/download";
import { getLocalFiles } from "services/fileService";
import { EnteFile } from "types/file";
import { getRenderableImage } from "utils/file";

export async function getLocalFile(fileId: number) {
    const localFiles = await getLocalFiles();
    return localFiles.find((f) => f.id === fileId);
}

export const fetchImageBitmap = async (file: EnteFile) =>
    fetchRenderableBlob(file).then(createImageBitmap);

async function fetchRenderableBlob(file: EnteFile) {
    const fileStream = await DownloadManager.getFile(file);
    const fileBlob = await new Response(fileStream).blob();
    if (file.metadata.fileType === FILE_TYPE.IMAGE) {
        return await getRenderableImage(file.metadata.title, fileBlob);
    } else {
        const { imageFileName, imageData } = await decodeLivePhoto(
            file.metadata.title,
            fileBlob,
        );
        return await getRenderableImage(imageFileName, new Blob([imageData]));
    }
}

export async function getLocalFileImageBitmap(
    enteFile: EnteFile,
    localFile: globalThis.File,
) {
    let fileBlob = localFile as Blob;
    fileBlob = await getRenderableImage(enteFile.metadata.title, fileBlob);
    return createImageBitmap(fileBlob);
}
