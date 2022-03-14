import ElectronStore from 'electron-store';
import path from 'path';
import * as fs from 'promise-fs';
import mime from 'mime';
import {
    Collection,
    FileWithCollection,
    StoreFileWithCollection,
} from '../types';
import { ENCRYPTION_CHUNK_SIZE } from '../../config';

const store = new ElectronStore();

export const setToUploadFiles = (
    files: FileWithCollection[],
    collections: Collection[],
    done: boolean
) => {
    store.set('done', done);
    if (done) {
        store.delete('files');
        store.delete('collections');
    } else {
        const filesList: StoreFileWithCollection[] = files.map(
            (file: FileWithCollection) => {
                return {
                    localID: file.localID,
                    collection: file.collection,
                    collectionID: file.collectionID,
                    filePath: file.file.path,
                };
            }
        );
        store.set('files', filesList);
        if (collections) store.set('collections', collections);
    }
};

export const getFileStream = async (filePath: string) => {
    const file = await fs.open(filePath, 'r');
    let offset = 0;
    const readableStream = new ReadableStream<Uint8Array>({
        async pull(controller) {
            let buff = new Uint8Array(ENCRYPTION_CHUNK_SIZE);

            // original types were not working correctly
            const bytesRead = (await fs.read(
                file,
                buff,
                0,
                ENCRYPTION_CHUNK_SIZE,
                offset
            )) as unknown as number;
            offset += bytesRead;
            if (bytesRead === 0) {
                controller.close();
                offset = 0;
            } else {
                controller.enqueue(buff);
            }
        },
    });
    return readableStream;
};

export const getToUploadFiles = async () => {
    const files = store.get('files') as StoreFileWithCollection[];
    if (!files)
        return {
            files: [] as FileWithCollection[],
            collections: [] as Collection[],
        };

    const filesWithStream: FileWithCollection[] = [];

    for (const file of files) {
        const filePath = file.filePath;

        if (fs.existsSync(filePath)) {
            const fileStats = fs.statSync(filePath);

            const fileObj: FileWithCollection = {
                localID: file.localID,
                collection: file.collection,
                collectionID: file.collectionID,

                file: {
                    path: filePath,
                    name: path.basename(filePath),
                    size: fileStats.size,
                    lastModified: fileStats.mtime.valueOf(),
                    type: {
                        mimeType: mime.getType(filePath),
                        ext: path.extname(filePath).substring(1),
                    },
                    createReadStream: async () => {
                        return await getFileStream(filePath);
                    },
                    toBlob: async () => {
                        const blob = await fs.readFile(filePath);
                        return new Blob([new Uint8Array(blob)]);
                    },
                    toUInt8Array: async () => {
                        const blob = await fs.readFile(filePath);
                        return new Uint8Array(blob);
                    },
                },
            };

            filesWithStream.push(fileObj);
        }
    }
    return {
        files: filesWithStream,
        collections: store.get('collections') as Collection[],
    };
};

export const getIfToUploadFilesExists = async () => {
    const done = store.get('done') as boolean;
    return done ? false : true;
};
