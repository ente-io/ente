import { FILE_TYPE } from 'pages/gallery';
import { logError } from 'utils/sentry';
import { getExifData } from './exifService';
import { MetadataObject } from './uploadService';

export interface Location {
    latitude: number;
    longitude: number;
}

export interface ParsedMetaDataJSON {
    title: string;
    creationTime: number;
    modificationTime: number;
    location: Location;
}

export const NULL_LOCATION: Location = { latitude: null, longitude: null };

const NULL_PARSED_METADATA_JSON: ParsedMetaDataJSON = {
    title: null,
    creationTime: null,
    modificationTime: null,
    location: NULL_LOCATION,
};

export async function extractMetatdata(
    reader: FileReader,
    receivedFile: globalThis.File,
    fileType: FILE_TYPE,
) {
    const { location, creationTime } = await getExifData(
        reader,
        receivedFile,
        fileType,
    );

    const extractedMetadata: MetadataObject = {
        title: receivedFile.name,
        creationTime: creationTime || receivedFile.lastModified * 1000,
        modificationTime: receivedFile.lastModified * 1000,
        latitude: location?.latitude,
        longitude: location?.latitude,
        fileType,
    };
    return extractedMetadata;
}

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

        parsedMetaDataJSON.title = metadataJSON['title'];
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
            parsedMetaDataJSON.location = locationData;
        }
        return parsedMetaDataJSON;
    } catch (e) {
        logError(e);
        // ignore
    }
}
