import exifr from 'exifr';
import { logError } from 'utils/sentry';

import { NULL_LOCATION, Location } from './metadataService';
import { FileTypeInfo } from './readFileService';

const EXIF_TAGS_NEEDED = [
    'DateTimeOriginal',
    'CreateDate',
    'ModifyDate',
    'GPSLatitude',
    'GPSLongitude',
    'GPSLatitudeRef',
    'GPSLongitudeRef',
];
interface Exif {
    DateTimeOriginal?: Date;
    CreateDate?: Date;
    ModifyDate?: Date;
    GPSLatitude?: number;
    GPSLongitude?: number;
    GPSLatitudeRef?: number;
    GPSLongitudeRef?: number;
}
interface ParsedEXIFData {
    location: Location;
    creationTime: number;
}

export async function getExifData(
    receivedFile: globalThis.File,
    fileTypeInfo: FileTypeInfo
): Promise<ParsedEXIFData> {
    const nullExifData: ParsedEXIFData = {
        location: NULL_LOCATION,
        creationTime: null,
    };
    try {
        const exifData = await getRawExif(receivedFile, fileTypeInfo);
        if (!exifData) {
            return nullExifData;
        }
        const parsedEXIFData = {
            location: getEXIFLocation(exifData),
            creationTime: getUNIXTime(
                exifData.DateTimeOriginal ??
                    exifData.CreateDate ??
                    exifData.ModifyDate
            ),
        };
        return parsedEXIFData;
    } catch (e) {
        logError(e, 'getExifData failed');
        return nullExifData;
    }
}

export async function getRawExif(
    receivedFile: File,
    fileTypeInfo: FileTypeInfo
) {
    let exifData: Exif;
    try {
        exifData = await exifr.parse(receivedFile, EXIF_TAGS_NEEDED);
    } catch (e) {
        logError(e, 'file missing exif data ', {
            fileType: fileTypeInfo.exactType,
        });
        // ignore exif parsing errors
    }
    return exifData;
}

export function getUNIXTime(dateTime: Date) {
    try {
        if (!dateTime) {
            return null;
        }
        const unixTime = dateTime.getTime() * 1000;
        if (unixTime <= 0) {
            return null;
        } else {
            return unixTime;
        }
    } catch (e) {
        logError(e, 'getUNIXTime failed', { dateTime });
    }
}

function getEXIFLocation(exifData): Location {
    if (!exifData.latitude || !exifData.longitude) {
        return NULL_LOCATION;
    }
    return { latitude: exifData.latitude, longitude: exifData.longitude };
}
