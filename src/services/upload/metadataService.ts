import { FILE_TYPE } from 'constants/file';
import { logError } from 'utils/sentry';
import { getExifData, ParsedEXIFData } from './exifService';
import {
    Metadata,
    ParsedMetadataJSON,
    Location,
    FileTypeInfo,
} from 'types/upload';
import { NULL_LOCATION } from 'constants/upload';
import { splitFilenameAndExtension } from 'utils/file';
import ffmpegService from 'services/ffmpegService';

enum VideoMetadata {
    CREATION_TIME = 'creation_time',
    APPLE_CONTENT_IDENTIFIER = 'com.apple.quicktime.content.identifier',
    APPLE_LIVE_PHOTO_IDENTIFIER = 'com.apple.quicktime.live-photo.auto',
    APPLE_CREATION_DATE = 'com.apple.quicktime.creationdate',
    APPLE_LOCATION_ISO = 'com.apple.quicktime.location.ISO6709',
}

interface ParsedMetadataJSONWithTitle {
    title: string;
    parsedMetadataJSON: ParsedMetadataJSON;
}

const NULL_PARSED_METADATA_JSON: ParsedMetadataJSON = {
    creationTime: null,
    modificationTime: null,
    ...NULL_LOCATION,
};

export interface ParsedVideoMetadata {
    location: Location;
    creationTime: number;
}

export async function extractMetadata(
    receivedFile: File,
    fileTypeInfo: FileTypeInfo
) {
    let exifData: ParsedEXIFData = null;
    let videoMetadata: ParsedVideoMetadata = null;
    if (fileTypeInfo.fileType === FILE_TYPE.IMAGE) {
        exifData = await getExifData(receivedFile, fileTypeInfo);
    } else if (fileTypeInfo.fileType === FILE_TYPE.VIDEO) {
        videoMetadata = await ffmpegService.extractMetadata(receivedFile);
    }

    const extractedMetadata: Metadata = {
        title: `${splitFilenameAndExtension(receivedFile.name)[0]}.${
            fileTypeInfo.exactType
        }`,
        creationTime:
            exifData?.creationTime ??
            videoMetadata.creationTime ??
            receivedFile.lastModified * 1000,
        modificationTime: receivedFile.lastModified * 1000,
        latitude:
            exifData?.location?.latitude ?? videoMetadata.location?.latitude,
        longitude:
            exifData?.location?.longitude ?? videoMetadata.location?.longitude,
        fileType: fileTypeInfo.fileType,
    };
    return extractedMetadata;
}

export const getMetadataJSONMapKey = (
    collectionID: number,

    title: string
) => `${collectionID}-${title}`;

export async function parseMetadataJSON(
    reader: FileReader,
    receivedFile: File
) {
    try {
        const metadataJSON: object = await new Promise((resolve, reject) => {
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

        const parsedMetadataJSON: ParsedMetadataJSON =
            NULL_PARSED_METADATA_JSON;
        if (!metadataJSON || !metadataJSON['title']) {
            return;
        }

        const title = metadataJSON['title'];
        if (
            metadataJSON['photoTakenTime'] &&
            metadataJSON['photoTakenTime']['timestamp']
        ) {
            parsedMetadataJSON.creationTime =
                metadataJSON['photoTakenTime']['timestamp'] * 1000000;
        } else if (
            metadataJSON['creationTime'] &&
            metadataJSON['creationTime']['timestamp']
        ) {
            parsedMetadataJSON.creationTime =
                metadataJSON['creationTime']['timestamp'] * 1000000;
        }
        if (
            metadataJSON['modificationTime'] &&
            metadataJSON['modificationTime']['timestamp']
        ) {
            parsedMetadataJSON.modificationTime =
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
            parsedMetadataJSON.latitude = locationData.latitude;
            parsedMetadataJSON.longitude = locationData.longitude;
        }
        return { title, parsedMetadataJSON } as ParsedMetadataJSONWithTitle;
    } catch (e) {
        logError(e, 'parseMetadataJSON failed');
        // ignore
    }
}

export function parseFFmpegExtractedMetadata(metadata: Uint8Array) {
    const metadataString = new TextDecoder().decode(metadata);
    const metadataPropertyArray = metadataString.split('\n');
    const metadataKeyValueArray = metadataPropertyArray.map((property) =>
        property.split('=')
    );
    const validKeyValuePairs = metadataKeyValueArray.filter(
        (keyValueArray) => keyValueArray.length === 2
    ) as Array<[string, string]>;

    const metadataMap = new Map(validKeyValuePairs);

    const location = parseAppleISOLocation(
        metadata[VideoMetadata.APPLE_LOCATION_ISO]
    );

    const parsedMetadata: ParsedVideoMetadata = {
        creationTime:
            metadataMap[VideoMetadata.APPLE_CREATION_DATE] ||
            metadataMap[VideoMetadata.CREATION_TIME],
        location: {
            latitude: location.latitude,
            longitude: location.longitude,
        },
    };
    return parsedMetadata;
}

function parseAppleISOLocation(isoLocation: string) {
    if (isoLocation) {
        const [latitude, longitude, altitude] = isoLocation
            .match(/(\+|-)\d+\.*\d+/g)
            .map((x) => parseFloat(x));

        return { latitude, longitude, altitude };
    }
}
