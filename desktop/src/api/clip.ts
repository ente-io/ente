import { ipcRenderer } from "electron";
import { writeStream } from "../services/fs";
import { Model } from "../types";
import { isExecError, parseExecError } from "../utils/error";

export async function computeImageEmbedding(
    model: Model,
    imageData: Uint8Array,
): Promise<Float32Array> {
    let tempInputFilePath = null;
    try {
        tempInputFilePath = await ipcRenderer.invoke("get-temp-file-path", "");
        const imageStream = new Response(imageData.buffer).body;
        await writeStream(tempInputFilePath, imageStream);
        const embedding = await ipcRenderer.invoke(
            "compute-image-embedding",
            model,
            tempInputFilePath,
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
            await ipcRenderer.invoke("remove-temp-file", tempInputFilePath);
        }
    }
}

export async function computeTextEmbedding(
    model: Model,
    text: string,
): Promise<Float32Array> {
    try {
        const embedding = await ipcRenderer.invoke(
            "compute-text-embedding",
            model,
            text,
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
