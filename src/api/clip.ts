import { ipcRenderer } from 'electron';
import { writeStream } from '../services/fs';

export async function computeImageEmbeddings(
    imageData: Uint8Array
): Promise<Float32Array> {
    let tempInputFilePath = null;
    try {
        tempInputFilePath = await ipcRenderer.invoke('get-temp-file-path', '');
        const imageStream = new Response(imageData.buffer).body;
        await writeStream(tempInputFilePath, imageStream);
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

export async function computeTextEmbeddings(
    text: string
): Promise<Float32Array> {
    const embeddings = await ipcRenderer.invoke(
        'compute-text-embeddings',
        text
    );
    return embeddings;
}
