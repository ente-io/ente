import { CHUNKS_COMBINED_FOR_A_UPLOAD_PART, DataStream, MultipartUploadURLs, RANDOM_PERCENTAGE_PROGRESS_FOR_PUT } from './uploadService';
import NetworkClient from './networkClient';
import * as convert from 'xml-js';


interface PartEtag{
    PartNumber:number;
    Etag:string;
}
export function calculatePartCount(encryptedChunkCount: number) {
    const partCount = Math.ceil(
        encryptedChunkCount / CHUNKS_COMBINED_FOR_A_UPLOAD_PART,
    );
    return partCount;
}
export async function uploadStreamUsingMultipart(filename:string, encryptedData:DataStream, progressTracker) {
    const { chunkCount, stream } = encryptedData;
    const uploadPartCount = calculatePartCount(chunkCount);
    const filePartUploadURLs = await NetworkClient.fetchMultipartUploadURLs(
        uploadPartCount,
    );
    const fileObjectKey = await uploadStreamInParts(
        filePartUploadURLs,
        stream,
        filename,
        uploadPartCount,
        progressTracker,
    );
    return fileObjectKey;
}

export async function uploadStreamInParts(
    multipartUploadURLs: MultipartUploadURLs,
    file: ReadableStream<Uint8Array>,
    filename: string,
    uploadPartCount: number,
    progressTracker,
) {
    const encryptedFileStreamReader = file.getReader();
    const percentPerPart = getRandomProgressPerPartUpload(uploadPartCount);

    const partEtags:PartEtag[] = [];
    for (const [
        index,
        fileUploadURL,
    ] of multipartUploadURLs.partURLs.entries()) {
        const uploadChunk = await combineChunksToFormUploadPart(encryptedFileStreamReader);
        const eTag= await NetworkClient.putFilePart(fileUploadURL, uploadChunk, progressTracker.bind(null, filename, percentPerPart, index));
        partEtags.push({ PartNumber: index+1, Etag: eTag });
    }
    await completeMultipartUpload(partEtags, multipartUploadURLs.completeURL);
    return multipartUploadURLs.objectKey;
}


export function getRandomProgressPerPartUpload(uploadPartCount:number) {
    const percentPerPart = Math.round(
        RANDOM_PERCENTAGE_PROGRESS_FOR_PUT() / uploadPartCount,
    );
    return percentPerPart;
}


export async function combineChunksToFormUploadPart(dataStreamReader:ReadableStreamDefaultReader<Uint8Array>) {
    const combinedChunks = [];
    for (let i = 0; i < CHUNKS_COMBINED_FOR_A_UPLOAD_PART; i++) {
        const { done, value: chunk } =
        await dataStreamReader.read();
        if (done) {
            break;
        }
        for (let index = 0; index < chunk.length; index++) {
            combinedChunks.push(chunk[index]);
        }
    }
    return Uint8Array.from(combinedChunks);
}


async function completeMultipartUpload(partEtags:PartEtag[], completeURL:string) {
    const options = { compact: true, ignoreComment: true, spaces: 4 };
    const body = convert.js2xml(
        { CompleteMultipartUpload: { Part: partEtags } },
        options,
    );
    await NetworkClient.completeMultipartUpload(completeURL, body);
}
