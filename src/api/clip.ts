import { ipcRenderer } from 'electron';
import { writeStream } from '../services/fs';
import { isExecError } from '../utils/error';
import { parseExecError } from '../utils/error';
import { Model } from '../types';

export async function computeImageEmbedding(
    model: Model,
    imageData: Uint8Array
): Promise<Float32Array> {
    let tempInputFilePath = null;
    try {
        tempInputFilePath = await ipcRenderer.invoke('get-temp-file-path', '');
        const imageStream = new Response(imageData.buffer).body;
        await writeStream(tempInputFilePath, imageStream);
        const embedding = await ipcRenderer.invoke(
            'compute-image-embedding',
            model,
            imageData
        );
        return embedding;
    } catch (err) {
        if (isExecError(err)) {
            const parsedExecError = parseExecError(err);
            throw Error(parsedExecError);
        } else {
            throw err;
        }
    } finally {
        if (tempInputFilePath) {
            await ipcRenderer.invoke('remove-temp-file', tempInputFilePath);
        }
    }
}

export async function computeTextEmbedding(
    text: string
): Promise<Float32Array> {
    try {
        const embedding = await ipcRenderer.invoke(
            'compute-text-embedding',
            text
        );
        return embedding;
    } catch (err) {
        if (isExecError(err)) {
            const parsedExecError = parseExecError(err);
            throw Error(parsedExecError);
        } else {
            throw err;
        }
    }
}
