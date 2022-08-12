import { FACE_CROPS_CACHE_NAME, MlFileData } from 'types/machineLearning';
import mlIDbStorage from 'utils/storage/mlIDbStorage';
import * as zip from '@zip.js/zip.js';
import { openCache } from 'utils/storage/cache';

class FileSystemWriter extends zip.Writer {
    writableStream: FileSystemWritableFileStream;

    constructor(writableStream: FileSystemWritableFileStream) {
        super();
        this.writableStream = writableStream;
    }

    async writeUint8Array(array: Uint8Array) {
        // console.log('zipWriter needs to write data: ', array.byteLength);
        return this.writableStream.write(array);
    }

    async getData() {
        return undefined;
    }
}

class FileReader extends zip.Reader {
    file: File;

    constructor(file: File) {
        super();
        this.file = file;
    }

    public async init() {
        this.size = this.file.size;
        // console.log('zipReader init, size: ', this.size);
    }

    public async readUint8Array(
        index: number,
        length: number
    ): Promise<Uint8Array> {
        // console.log('zipReader needs data: ', index, length);
        const slicedFile = this.file.slice(index, index + length);
        const arrayBuffer = await slicedFile.arrayBuffer();

        return new Uint8Array(arrayBuffer);
    }
}

export async function exportMlData(
    mlDataZipWritable: FileSystemWritableFileStream
) {
    const zipWriter = new zip.ZipWriter(
        new FileSystemWriter(mlDataZipWritable)
    );

    try {
        try {
            await exportMlDataToZipWriter(zipWriter);
        } finally {
            await zipWriter.close();
        }
    } catch (e) {
        await mlDataZipWritable.abort();
        throw e;
    }

    await mlDataZipWritable.close();
    console.log('Ml Data Exported');
}

async function exportMlDataToZipWriter(zipWriter: zip.ZipWriter) {
    const mlDbData = await mlIDbStorage.getAllMLData();
    const faceClusteringResults =
        mlDbData?.library?.data?.faceClusteringResults;
    faceClusteringResults && (faceClusteringResults.debugInfo = undefined);
    console.log(
        'Exporting ML DB data: ',
        Object.keys(mlDbData),
        Object.keys(mlDbData)?.map((k) => Object.keys(mlDbData[k])?.length)
    );
    await zipWriter.add(
        'indexeddb/mldata.json',
        new zip.TextReader(JSON.stringify(mlDbData))
    );

    const faceCropCache = await openCache(FACE_CROPS_CACHE_NAME);
    const files =
        mlDbData['files'] && (Object.values(mlDbData['files']) as MlFileData[]);
    for (const fileData of files || []) {
        for (const face of fileData.faces || []) {
            const faceCropUrl = face.crop?.imageUrl;
            if (!faceCropUrl) {
                console.error('face crop not found for faceId: ', face.id);
                continue;
            }
            const response = await faceCropCache.match(faceCropUrl);
            if (response && response.ok) {
                const blob = await response.blob();
                await zipWriter.add(
                    `caches/${FACE_CROPS_CACHE_NAME}${faceCropUrl}`,
                    new zip.BlobReader(blob),
                    { level: 0 }
                );
            } else {
                console.error(
                    'face crop cache entry not found for faceCropUrl: ',
                    faceCropUrl
                );
            }
        }
    }
}
export async function importMlData(mlDataZipFile: File) {
    const zipReader = new zip.ZipReader(new FileReader(mlDataZipFile));

    try {
        await importMlDataFromZipReader(zipReader);
    } finally {
        await zipReader.close();
    }

    console.log('ML Data Imported');
}

async function importMlDataFromZipReader(zipReader: zip.ZipReader) {
    const zipEntries = await zipReader.getEntries();
    // console.log(zipEntries);

    const faceCropPath = `caches/${FACE_CROPS_CACHE_NAME}`;
    const faceCropCache = await openCache(FACE_CROPS_CACHE_NAME);
    let mldataEntry;
    for (const entry of zipEntries) {
        if (entry.filename === 'indexeddb/mldata.json') {
            mldataEntry = entry;
        } else if (entry.filename.startsWith(faceCropPath)) {
            const faceCropUrl = entry.filename.substring(faceCropPath.length);
            // console.log('importing faceCropUrl: ', faceCropUrl);
            const faceCropCacheBlob: Blob = await entry.getData(
                new zip.BlobWriter('image/jpeg')
            );
            faceCropCache.put(faceCropUrl, new Response(faceCropCacheBlob));
        }
    }

    const mlDataJsonStr: string = await mldataEntry.getData(
        new zip.TextWriter()
    );
    const mlDbData = JSON.parse(mlDataJsonStr);
    console.log(
        'importing ML DB data: ',
        Object.keys(mlDbData),
        Object.keys(mlDbData)?.map((k) => Object.keys(mlDbData[k])?.length)
    );
    await mlIDbStorage.putAllMLData(mlDbData);
}
