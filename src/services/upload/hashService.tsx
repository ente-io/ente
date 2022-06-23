import { FILE_READER_CHUNK_SIZE } from 'constants/upload';
import { getFileStream, getElectronFileStream } from 'services/readerService';
import { ElectronFile, DataStream } from 'types/upload';
import CryptoWorker from 'utils/crypto';
import { logError } from 'utils/sentry';

export async function getFileHash(file: File | ElectronFile) {
    try {
        let filedata: DataStream;
        if (file instanceof File) {
            filedata = getFileStream(file, FILE_READER_CHUNK_SIZE);
        } else {
            filedata = await getElectronFileStream(
                file,
                FILE_READER_CHUNK_SIZE
            );
        }
        const cryptoWorker = await new CryptoWorker();
        const hashState = await cryptoWorker.initChunkHashing();

        const reader = filedata.stream.getReader();
        // eslint-disable-next-line no-constant-condition
        while (true) {
            const { done, value: chunk } = await reader.read();
            if (done) {
                break;
            }
            await cryptoWorker.hashFileChunk(hashState, Uint8Array.from(chunk));
        }
        const hash = await cryptoWorker.completeChunkHashing(hashState);
        return hash;
    } catch (e) {
        logError(e, 'getFileHash failed');
        throw e;
    }
}
