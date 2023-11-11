import { Remote } from 'comlink';
import { FILE_READER_CHUNK_SIZE } from 'constants/upload';
import { getFileStream, getElectronFileStream } from 'services/readerService';
import { ElectronFile, DataStream } from 'types/upload';
import { CustomError } from '@ente/shared/error';
import { addLogLine } from '@ente/shared/logging';
import { getFileNameSize } from '@ente/shared/logging/web';
import { logError } from '@ente/shared/sentry';
import { DedicatedCryptoWorker } from '@ente/shared/crypto/internal/crypto.worker';

export async function getFileHash(
    worker: Remote<DedicatedCryptoWorker>,
    file: File | ElectronFile
) {
    try {
        addLogLine(`getFileHash called for ${getFileNameSize(file)}`);
        let filedata: DataStream;
        if (file instanceof File) {
            filedata = getFileStream(file, FILE_READER_CHUNK_SIZE);
        } else {
            filedata = await getElectronFileStream(
                file,
                FILE_READER_CHUNK_SIZE
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
        addLogLine(
            `file hashing completed successfully ${getFileNameSize(file)}`
        );
        return hash;
    } catch (e) {
        logError(e, 'getFileHash failed');
        addLogLine(
            `file hashing failed ${getFileNameSize(file)} ,${e.message} `
        );
    }
}
