import { FILE_TYPE } from 'constants/file';
import { logError } from 'utils/sentry';
import { getExifData } from './exifService';
import {
    MetadataObject,
    ParsedMetaDataJSON,
    Location,
    FileTypeInfo,
} from 'types/upload';
import { NULL_LOCATION } from 'constants/upload';

interface ParsedMetaDataJSONWithTitle {
    title: string;
    parsedMetaDataJSON: ParsedMetaDataJSON;
}

const NULL_PARSED_METADATA_JSON: ParsedMetaDataJSON = {
    creationTime: null,
    modificationTime: null,
    ...NULL_LOCATION,
};

export async function extractMetadata(
    receivedFile: File,
    fileTypeInfo: FileTypeInfo
) {
    let exifData = null;
    if (fileTypeInfo.fileType === FILE_TYPE.IMAGE) {
        exifData = await getExifData(receivedFile, fileTypeInfo);
    }

    const extractedMetadata: MetadataObject = {
        title: receivedFile.name,
        creationTime:
            exifData?.creationTime ?? receivedFile.lastModified * 1000,
        modificationTime: receivedFile.lastModified * 1000,
        latitude: exifData?.location?.latitude,
        longitude: exifData?.location?.longitude,
        fileType: fileTypeInfo.fileType,
    };
    return extractedMetadata;
}

export const getMetadataMapKey = (collectionID: number, title: string) =>
    `${collectionID}_${title}`;

export async function parseMetadataJSON(receivedFile: File) {
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
