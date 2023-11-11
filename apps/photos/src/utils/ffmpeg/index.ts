import { NULL_LOCATION } from 'constants/upload';
import { ParsedExtractedMetadata } from 'types/upload';
import { validateAndGetCreationUnixTimeInMicroSeconds } from '@ente/shared/time';

enum MetadataTags {
    CREATION_TIME = 'creation_time',
    APPLE_CONTENT_IDENTIFIER = 'com.apple.quicktime.content.identifier',
    APPLE_LIVE_PHOTO_IDENTIFIER = 'com.apple.quicktime.live-photo.auto',
    APPLE_CREATION_DATE = 'com.apple.quicktime.creationdate',
    APPLE_LOCATION_ISO = 'com.apple.quicktime.location.ISO6709',
    LOCATION = 'location',
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
        metadataMap[MetadataTags.APPLE_LOCATION_ISO] ??
            metadataMap[MetadataTags.LOCATION]
    );

    const creationTime = parseCreationTime(
        metadataMap[MetadataTags.APPLE_CREATION_DATE] ??
            metadataMap[MetadataTags.CREATION_TIME]
    );
    const parsedMetadata: ParsedExtractedMetadata = {
        creationTime,
        location: {
            latitude: location.latitude,
            longitude: location.longitude,
        },
        width: null,
        height: null,
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
        dateTime = validateAndGetCreationUnixTimeInMicroSeconds(
            new Date(creationTime)
        );
    }
    return dateTime;
}

export function splitFilenameAndExtension(filename: string): [string, string] {
    const lastDotPosition = filename.lastIndexOf('.');
    if (lastDotPosition === -1) return [filename, null];
    else
        return [
            filename.slice(0, lastDotPosition),
            filename.slice(lastDotPosition + 1),
        ];
}
