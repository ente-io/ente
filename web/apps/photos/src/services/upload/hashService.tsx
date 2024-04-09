import { getFileNameSize } from "@/next/file";
import log from "@/next/log";
import { DedicatedCryptoWorker } from "@ente/shared/crypto/internal/crypto.worker";
import { CustomError } from "@ente/shared/error";
import { Remote } from "comlink";
import { FILE_READER_CHUNK_SIZE } from "constants/upload";
import { getElectronFileStream, getFileStream } from "services/readerService";
import { DataStream, ElectronFile } from "types/upload";

export async function getFileHash(
    worker: Remote<DedicatedCryptoWorker>,
    file: File | ElectronFile,
) {
    try {
        log.info(`getFileHash called for ${getFileNameSize(file)}`);
        let filedata: DataStream;
        if (file instanceof File) {
            filedata = getFileStream(file, FILE_READER_CHUNK_SIZE);
        } else {
            filedata = await getElectronFileStream(
                file,
                FILE_READER_CHUNK_SIZE,
            );
        }
        const hashState = await worker.initChunkHashing();

        const streamReader = filedata.stream.getReader();
        for (let i = 0; i < filedata.chunkCount; i++) {
            const { done, value: chunk } = await streamReader.read();
            if (done) {
                throw Error(CustomError.CHUNK_LESS_THAN_EXPECTED);
            }
            await worker.hashFileChunk(hashState, Uint8Array.from(chunk));
        }
        const { done } = await streamReader.read();
        if (!done) {
            throw Error(CustomError.CHUNK_MORE_THAN_EXPECTED);
        }
        const hash = await worker.completeChunkHashing(hashState);
        log.info(
            `file hashing completed successfully ${getFileNameSize(file)}`,
        );
        return hash;
    } catch (e) {
        log.error("getFileHash failed", e);
        log.info(`file hashing failed ${getFileNameSize(file)} ,${e.message} `);
    }
}
