import { FILE_TYPE } from 'pages/gallery';
import { ENCRYPTION_CHUNK_SIZE } from 'types';
import { THUMBNAIL_GENERATION_FAILED } from 'utils/common/errorUtil';
import { fileIsHEIC, convertHEIC2JPEG } from 'utils/file';
import { logError } from 'utils/sentry';
import { getExifData } from './exifService';

const TYPE_VIDEO = 'video';
const TYPE_HEIC = 'HEIC';
export const TYPE_IMAGE = 'image';
const MIN_STREAM_FILE_SIZE = 20 * 1024 * 1024;
const EDITED_FILE_SUFFIX = '-edited';
const THUMBNAIL_HEIGHT = 720;
const MAX_ATTEMPTS = 3;
const MIN_THUMBNAIL_SIZE = 50000;


export const NULL_LOCATION: Location = { latitude: null, longitude: null };
const WAIT_TIME_THUMBNAIL_GENERATION = 10 * 1000;
const NULL_PARSED_METADATA_JSON:ParsedMetaDataJSON={ title: null, creationTime: null, modificationTime: null, location: NULL_LOCATION };

export interface Location {
    latitude: number;
    longitude: number;
}


export interface ParsedMetaDataJSON{
    title:string;
    creationTime:number;
    modificationTime:number;
    location:Location;
}

export default async function readFile(reader: FileReader, receivedFile: globalThis.File, metadataMap:Map<string, Object>) {
    try {
        const { thumbnail, hasStaticThumbnail } = await generateThumbnail(
            reader,
            receivedFile,
        );

        let fileType: FILE_TYPE;
        switch (receivedFile.type.split('/')[0]) {
            case TYPE_IMAGE:
                fileType = FILE_TYPE.IMAGE;
                break;
            case TYPE_VIDEO:
                fileType = FILE_TYPE.VIDEO;
                break;
            default:
                fileType = FILE_TYPE.OTHERS;
        }
        if (
            fileType === FILE_TYPE.OTHERS &&
            receivedFile.type.length === 0 &&
            receivedFile.name.endsWith(TYPE_HEIC)
        ) {
            fileType = FILE_TYPE.IMAGE;
        }

        const { location, creationTime } = await getExifData(
            reader,
            receivedFile,
            fileType,
        );
        let receivedFileOriginalName = receivedFile.name;
        if (receivedFile.name.endsWith(EDITED_FILE_SUFFIX)) {
            receivedFileOriginalName = receivedFile.name.slice(
                0,
                -1 * EDITED_FILE_SUFFIX.length,
            );
        }
        const metadata = Object.assign(
            {
                title: receivedFile.name,
                creationTime:
                    creationTime || receivedFile.lastModified * 1000,
                modificationTime: receivedFile.lastModified * 1000,
                latitude: location?.latitude,
                longitude: location?.latitude,
                fileType,
            },
            metadataMap.get(receivedFileOriginalName),
        );
        if (hasStaticThumbnail) {
            metadata['hasStaticThumbnail'] = hasStaticThumbnail;
        }
        const filedata =
            receivedFile.size > MIN_STREAM_FILE_SIZE ?
                getFileStream(reader, receivedFile) :
                await getUint8ArrayView(reader, receivedFile);

        return {
            filedata,
            thumbnail,
            metadata,
        };
    } catch (e) {
        logError(e, 'error reading files');
        throw e;
    }
}

async function generateThumbnail(
    reader: FileReader,
    file: globalThis.File,
): Promise<{ thumbnail: Uint8Array, hasStaticThumbnail: boolean }> {
    try {
        let hasStaticThumbnail = false;
        const canvas = document.createElement('canvas');
        // eslint-disable-next-line camelcase
        const canvas_CTX = canvas.getContext('2d');
        let imageURL = null;
        let timeout = null;
        try {
            if (file.type.match(TYPE_IMAGE) || fileIsHEIC(file.name)) {
                if (fileIsHEIC(file.name)) {
                    file = new globalThis.File(
                        [await convertHEIC2JPEG(file)],
                        null,
                        null,
                    );
                }
                let image = new Image();
                imageURL = URL.createObjectURL(file);
                image.setAttribute('src', imageURL);
                await new Promise((resolve, reject) => {
                    image.onload = () => {
                        try {
                            const thumbnailWidth =
                                (image.width * THUMBNAIL_HEIGHT) / image.height;
                            canvas.width = thumbnailWidth;
                            canvas.height = THUMBNAIL_HEIGHT;
                            canvas_CTX.drawImage(
                                image,
                                0,
                                0,
                                thumbnailWidth,
                                THUMBNAIL_HEIGHT,
                            );
                            image = null;
                            clearTimeout(timeout);
                            resolve(null);
                        } catch (e) {
                            reject(e);
                            logError(e);
                            reject(Error(`${THUMBNAIL_GENERATION_FAILED} err: ${e}`));
                        }
                    };
                    timeout = setTimeout(
                        () =>
                            reject(
                                Error(`wait time exceeded for format ${file.name.split('.').slice(-1)[0]}`),
                            ),
                        WAIT_TIME_THUMBNAIL_GENERATION,
                    );
                });
            } else {
                await new Promise((resolve, reject) => {
                    let video = document.createElement('video');
                    imageURL = URL.createObjectURL(file);
                    video.addEventListener('timeupdate', function () {
                        try {
                            if (!video) {
                                return;
                            }
                            const thumbnailWidth =
                                (video.videoWidth * THUMBNAIL_HEIGHT) /
                                video.videoHeight;
                            canvas.width = thumbnailWidth;
                            canvas.height = THUMBNAIL_HEIGHT;
                            canvas_CTX.drawImage(
                                video,
                                0,
                                0,
                                thumbnailWidth,
                                THUMBNAIL_HEIGHT,
                            );
                            video = null;
                            clearTimeout(timeout);
                            resolve(null);
                        } catch (e) {
                            reject(e);
                            logError(e);
                            reject(Error(`${THUMBNAIL_GENERATION_FAILED} err: ${e}`));
                        }
                    });
                    video.preload = 'metadata';
                    video.src = imageURL;
                    video.currentTime = 3;
                    setTimeout(
                        () =>
                            reject(Error(`wait time exceeded for format ${file.name.split('.').slice(-1)[0]}`)),
                        WAIT_TIME_THUMBNAIL_GENERATION,
                    );
                });
            }
            URL.revokeObjectURL(imageURL);
        } catch (e) {
            logError(e);
            // ignore and set staticThumbnail
            hasStaticThumbnail = true;
        }
        let thumbnailBlob = null;
        let attempts = 0;
        let quality = 1;

        do {
            attempts++;
            quality /= 2;
            thumbnailBlob = await new Promise((resolve) => {
                canvas.toBlob(
                    function (blob) {
                        resolve(blob);
                    },
                    'image/jpeg',
                    quality,
                );
            });
            thumbnailBlob = thumbnailBlob ?? new Blob([]);
        } while (
            thumbnailBlob.size > MIN_THUMBNAIL_SIZE &&
            attempts <= MAX_ATTEMPTS
        );
        const thumbnail = await getUint8ArrayView(
            reader,
            thumbnailBlob,
        );
        return { thumbnail, hasStaticThumbnail };
    } catch (e) {
        logError(e, 'Error generating thumbnail');
        throw e;
    }
}

function getFileStream(reader: FileReader, file: globalThis.File) {
    const self = this;
    const fileChunkReader = (async function* fileChunkReaderMaker(
        fileSize,
        self,
    ) {
        let offset = 0;
        while (offset < fileSize) {
            const blob = file.slice(offset, ENCRYPTION_CHUNK_SIZE + offset);
            const fileChunk = await self.getUint8ArrayView(reader, blob);
            yield fileChunk;
            offset += ENCRYPTION_CHUNK_SIZE;
        }
        return null;
    })(file.size, self);
    return {
        stream: new ReadableStream<Uint8Array>({
            async pull(controller: ReadableStreamDefaultController) {
                const chunk = await fileChunkReader.next();
                if (chunk.done) {
                    controller.close();
                } else {
                    controller.enqueue(chunk.value);
                }
            },
        }),
        chunkCount: Math.ceil(file.size / ENCRYPTION_CHUNK_SIZE),
    };
}
async function getUint8ArrayView(
    reader: FileReader,
    file: Blob,
): Promise<Uint8Array> {
    try {
        return await new Promise((resolve, reject) => {
            reader.onabort = () => reject(Error('file reading was aborted'));
            reader.onerror = () => reject(Error('file reading has failed'));
            reader.onload = () => {
                // Do whatever you want with the file contents
                const result =
                    typeof reader.result === 'string' ?
                        new TextEncoder().encode(reader.result) :
                        new Uint8Array(reader.result);
                resolve(result);
            };
            reader.readAsArrayBuffer(file);
        });
    } catch (e) {
        logError(e, 'error reading file to byte-array');
        throw e;
    }
}


export async function parseMetadataJSON(receivedFile: globalThis.File) {
    try {
        const metadataJSON: object = await new Promise(
            (resolve, reject) => {
                const reader = new FileReader();
                reader.onabort = () => reject(Error('file reading was aborted'));
                reader.onerror = () => reject(Error('file reading has failed'));
                reader.onload = () => {
                    const result =
                        typeof reader.result !== 'string' ?
                            new TextDecoder().decode(reader.result) :
                            reader.result;
                    resolve(JSON.parse(result));
                };
                reader.readAsText(receivedFile);
            },
        );

        const parsedMetaDataJSON:ParsedMetaDataJSON = NULL_PARSED_METADATA_JSON;
        if (!metadataJSON || !metadataJSON['title']) {
            return;
        }

        parsedMetaDataJSON.title=metadataJSON['title'];
        if (
            metadataJSON['photoTakenTime'] &&
            metadataJSON['photoTakenTime']['timestamp']
        ) {
            parsedMetaDataJSON.creationTime =
                metadataJSON['photoTakenTime']['timestamp'] * 1000000;
        }
        if (
            metadataJSON['modificationTime'] &&
            metadataJSON['modificationTime']['timestamp']
        ) {
            parsedMetaDataJSON.modificationTime =
                metadataJSON['modificationTime']['timestamp'] * 1000000;
        }
        let locationData:Location = NULL_LOCATION;
        if (
            metadataJSON['geoData'] &&
            (metadataJSON['geoData']['latitude'] !== 0.0 ||
                metadataJSON['geoData']['longitude'] !== 0.0)
        ) {
            locationData = metadataJSON['geoData'];
        } else if (
            metadataJSON['geoDataExif'] &&
            (metadataJSON['geoDataExif']['latitude'] !== 0.0 ||
                metadataJSON['geoDataExif']['longitude'] !== 0.0)
        ) {
            locationData = metadataJSON['geoDataExif'];
        }
        if (locationData !== null) {
            parsedMetaDataJSON.location=locationData;
        }
        return parsedMetaDataJSON;
    } catch (e) {
        logError(e);
        // ignore
    }
}
