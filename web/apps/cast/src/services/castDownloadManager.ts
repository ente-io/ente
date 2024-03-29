import { CustomError } from "@ente/shared/error";
import HTTPService from "@ente/shared/network/HTTPService";
import { getCastFileURL } from "@ente/shared/network/api";
import { FILE_TYPE } from "constants/file";
import { EnteFile } from "types/file";
import ComlinkCryptoWorker from "utils/comlink/ComlinkCryptoWorker";
import { generateStreamFromArrayBuffer } from "utils/file";

class CastDownloadManager {
    async downloadFile(castToken: string, file: EnteFile) {
        const cryptoWorker = await ComlinkCryptoWorker.getInstance();

        if (
            file.metadata.fileType === FILE_TYPE.IMAGE ||
            file.metadata.fileType === FILE_TYPE.LIVE_PHOTO
        ) {
            const resp = await HTTPService.get(
                getCastFileURL(file.id),
                null,
                {
                    "X-Cast-Access-Token": castToken,
                },
                { responseType: "arraybuffer" },
            );
            if (typeof resp.data === "undefined") {
                throw Error(CustomError.REQUEST_FAILED);
            }
            const decrypted = await cryptoWorker.decryptFile(
                new Uint8Array(resp.data),
                await cryptoWorker.fromB64(file.file.decryptionHeader),
                file.key,
            );
            return generateStreamFromArrayBuffer(decrypted);
        }
        const resp = await fetch(getCastFileURL(file.id), {
            headers: {
                "X-Cast-Access-Token": castToken,
            },
        });
        const reader = resp.body.getReader();

        const stream = new ReadableStream({
            async start(controller) {
                const decryptionHeader = await cryptoWorker.fromB64(
                    file.file.decryptionHeader,
                );
                const fileKey = await cryptoWorker.fromB64(file.key);
                const { pullState, decryptionChunkSize } =
                    await cryptoWorker.initChunkDecryption(
                        decryptionHeader,
                        fileKey,
                    );
                let data = new Uint8Array();
                // The following function handles each data chunk
                function push() {
                    // "done" is a Boolean and value a "Uint8Array"
                    reader.read().then(async ({ done, value }) => {
                        // Is there more data to read?
                        if (!done) {
                            const buffer = new Uint8Array(
                                data.byteLength + value.byteLength,
                            );
                            buffer.set(new Uint8Array(data), 0);
                            buffer.set(new Uint8Array(value), data.byteLength);
                            if (buffer.length > decryptionChunkSize) {
                                const fileData = buffer.slice(
                                    0,
                                    decryptionChunkSize,
                                );
                                const { decryptedData } =
                                    await cryptoWorker.decryptFileChunk(
                                        fileData,
                                        pullState,
                                    );
                                controller.enqueue(decryptedData);
                                data = buffer.slice(decryptionChunkSize);
                            } else {
                                data = buffer;
                            }
                            push();
                        } else {
                            if (data) {
                                const { decryptedData } =
                                    await cryptoWorker.decryptFileChunk(
                                        data,
                                        pullState,
                                    );
                                controller.enqueue(decryptedData);
                                data = null;
                            }
                            controller.close();
                        }
                    });
                }

                push();
            },
        });
        return stream;
    }
}

export default new CastDownloadManager();
