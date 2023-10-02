import { ipcRenderer } from 'electron';
import { writeStream } from '../services/fs';

export async function computeImageEmbeddings(
    imageFile: File
): Promise<Float32Array> {
    let tempInputFilePath = null;
    try {
        tempInputFilePath = await ipcRenderer.invoke(
            'get-temp-file-path',
            imageFile.name
        );
        await writeStream(tempInputFilePath, imageFile.stream());
        const embeddings = await ipcRenderer.invoke(
            'compute-image-embeddings',
            tempInputFilePath
        );
        return embeddings;
    } finally {
        if (tempInputFilePath) {
            await ipcRenderer.invoke('remove-temp-file', tempInputFilePath);
        }
    }
}
