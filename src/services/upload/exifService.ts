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
interface ParsedEXIFData {
    location: Location;
    creationTime: number;
}

export async function getExifData(
    receivedFile: globalThis.File,
    fileTypeInfo: FileTypeInfo
): Promise<ParsedEXIFData> {
    let exifData;
    try {
        exifData = await exifr.parse(receivedFile, EXIF_TAGS_NEEDED);
    } catch (e) {
        logError(e, 'file missing exif data ', {
            fileType: fileTypeInfo.exactType,
        });
        // ignore exif parsing errors
    }
    if (!exifData) {
        return { location: NULL_LOCATION, creationTime: null };
    }
    const parsedEXIFData = {
        location: getEXIFLocation(exifData),
        creationTime: getUNIXTime(exifData),
    };
    return parsedEXIFData;
}

function getUNIXTime(exifData: any) {
    const dateTime: Date =
        exifData.DateTimeOriginal ?? exifData.CreateDate ?? exifData.ModifyDate;

    if (!dateTime) {
        return null;
    }
    const unixTime = dateTime.getTime() * 1000;
    if (unixTime <= 0) {
        return null;
    } else {
        return unixTime;
    }
}

function getEXIFLocation(exifData): Location {
    if (!exifData.latitude || !exifData.longitude) {
        return NULL_LOCATION;
    }
    return { latitude: exifData.latitude, longitude: exifData.longitude };
}
