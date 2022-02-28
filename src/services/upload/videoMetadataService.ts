import { NULL_EXTRACTED_METADATA, NULL_LOCATION } from 'constants/upload';
import ffmpegService from 'services/ffmpegService';
import { getUNIXTime } from 'utils/time';
import { ParsedExtractedMetadata } from 'types/upload';
import { logError } from 'utils/sentry';

enum VideoMetadata {
    CREATION_TIME = 'creation_time',
    APPLE_CONTENT_IDENTIFIER = 'com.apple.quicktime.content.identifier',
    APPLE_LIVE_PHOTO_IDENTIFIER = 'com.apple.quicktime.live-photo.auto',
    APPLE_CREATION_DATE = 'com.apple.quicktime.creationdate',
    APPLE_LOCATION_ISO = 'com.apple.quicktime.location.ISO6709',
}

export async function getVideoMetadata(file: File) {
    let videoMetadata = NULL_EXTRACTED_METADATA;
    try {
        videoMetadata = await ffmpegService.extractMetadata(file);
    } catch (e) {
        logError(e, 'failed to get video metadata');
    }

    return videoMetadata;
}

export function parseFFmpegExtractedMetadata(encodedMetadata: Uint8Array) {
    const metadataString = new TextDecoder().decode(encodedMetadata);
    const metadataPropertyArray = metadataString.split('\n');
    const metadataKeyValueArray = metadataPropertyArray.map((property) =>
        property.split('=')
    );
    const validKeyValuePairs = metadataKeyValueArray.filter(
        (keyValueArray) => keyValueArray.length === 2
    ) as Array<[string, string]>;

    const metadataMap = Object.fromEntries(validKeyValuePairs);

    const location = parseAppleISOLocation(
        metadataMap[VideoMetadata.APPLE_LOCATION_ISO]
    );

    const creationTime = parseCreationTime(
        metadataMap[VideoMetadata.APPLE_CREATION_DATE] ??
            metadataMap[VideoMetadata.CREATION_TIME]
    );
    const parsedMetadata: ParsedExtractedMetadata = {
        creationTime,
        location: {
            latitude: location.latitude,
            longitude: location.longitude,
        },
    };
    return parsedMetadata;
}

function parseAppleISOLocation(isoLocation: string) {
    let location = NULL_LOCATION;
    if (isoLocation) {
        const [latitude, longitude] = isoLocation
            .match(/(\+|-)\d+\.*\d+/g)
            .map((x) => parseFloat(x));

        location = { latitude, longitude };
    }
    return location;
}

function parseCreationTime(creationTime: string) {
    let dateTime = null;
    if (creationTime) {
        dateTime = getUNIXTime(new Date(creationTime));
    }
    return dateTime;
}
