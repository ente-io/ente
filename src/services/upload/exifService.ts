import exifr from 'exifr';

import { logError } from 'utils/sentry';
import { NULL_LOCATION, Location } from './metadataService';

const EXIF_TAGS_NEEDED = [
    'DateTimeOriginal',
    'CreateDate',
    'ModifyDate',
    'GPSLatitude',
    'GPSLongitude',
    'GPSLatitudeRef',
    'GPSLongitudeRef',
];
interface ParsedEXIFData {
    location: Location;
    creationTime: number;
}

export async function getExifData(
    receivedFile: globalThis.File
): Promise<ParsedEXIFData> {
    try {
        const exifData = await exifr.parse(receivedFile, EXIF_TAGS_NEEDED);
        if (!exifData) {
            return { location: NULL_LOCATION, creationTime: null };
        }
        const parsedEXIFData = {
            location: getEXIFLocation(exifData),
            creationTime: getUNIXTime(exifData),
        };
        return parsedEXIFData;
    } catch (e) {
        logError(e, 'error reading exif data');
        // ignore exif parsing errors
    }
}

function getUNIXTime(exifData: any) {
    const dateTime =
        exifData.DateTimeOriginal ?? exifData.CreateDate ?? exifData.ModifyDate;

    if (!dateTime) {
        return null;
    }
    return dateTime.getTime() * 1000;
}

function getEXIFLocation(exifData): Location {
    if (!exifData.latitude || !exifData.longitude) {
        return NULL_LOCATION;
    }
    return { latitude: exifData.latitude, longitude: exifData.longitude };
}
