import { logError } from 'utils/sentry';
import { getExifData } from './exifService';
import { FileTypeInfo } from './readFileService';
import { MetadataObject } from './uploadService';

export interface Location {
    latitude: number;
    longitude: number;
}

export interface ParsedMetaDataJSON {
    creationTime: number;
    modificationTime: number;
    latitude: number;
    longitude: number;
}
interface ParsedMetaDataJSONWithTitle {
    title: string;
    parsedMetaDataJSON: ParsedMetaDataJSON;
}

export const NULL_LOCATION: Location = { latitude: null, longitude: null };

const NULL_PARSED_METADATA_JSON: ParsedMetaDataJSON = {
    creationTime: null,
    modificationTime: null,
    ...NULL_LOCATION,
};

export async function extractMetadata(
    worker,
    receivedFile: globalThis.File,
    fileTypeInfo: FileTypeInfo
) {
    const { location, creationTime } = await getExifData(worker, receivedFile);

    const extractedMetadata: MetadataObject = {
        title: receivedFile.name,
        creationTime: creationTime || receivedFile.lastModified * 1000,
        modificationTime: receivedFile.lastModified * 1000,
        latitude: location?.latitude,
        longitude: location?.longitude,
        fileType: fileTypeInfo.fileType,
    };
    return extractedMetadata;
}

export const getMetadataMapKey = (collectionID: number, title: string) =>
    `${collectionID}_${title}`;

export async function parseMetadataJSON(receivedFile: globalThis.File) {
    try {
        const metadataJSON: object = await new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onabort = () => reject(Error('file reading was aborted'));
            reader.onerror = () => reject(Error('file reading has failed'));
            reader.onload = () => {
                const result =
                    typeof reader.result !== 'string'
                        ? new TextDecoder().decode(reader.result)
                        : reader.result;
                resolve(JSON.parse(result));
            };
            reader.readAsText(receivedFile);
        });

        const parsedMetaDataJSON: ParsedMetaDataJSON =
            NULL_PARSED_METADATA_JSON;
        if (!metadataJSON || !metadataJSON['title']) {
            return;
        }

        const title = metadataJSON['title'];
        if (
            metadataJSON['photoTakenTime'] &&
            metadataJSON['photoTakenTime']['timestamp']
        ) {
            parsedMetaDataJSON.creationTime =
                metadataJSON['photoTakenTime']['timestamp'] * 1000000;
        } else if (
            metadataJSON['creationTime'] &&
            metadataJSON['creationTime']['timestamp']
        ) {
            parsedMetaDataJSON.creationTime =
                metadataJSON['creationTime']['timestamp'] * 1000000;
        }
        if (
            metadataJSON['modificationTime'] &&
            metadataJSON['modificationTime']['timestamp']
        ) {
            parsedMetaDataJSON.modificationTime =
                metadataJSON['modificationTime']['timestamp'] * 1000000;
        }
        let locationData: Location = NULL_LOCATION;
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
            parsedMetaDataJSON.latitude = locationData.latitude;
            parsedMetaDataJSON.longitude = locationData.longitude;
        }
        return { title, parsedMetaDataJSON } as ParsedMetaDataJSONWithTitle;
    } catch (e) {
        logError(e, 'parseMetadataJSON failed');
        // ignore
    }
}
