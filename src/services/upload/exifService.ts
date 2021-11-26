import exifr from 'exifr';
import piexif from 'piexifjs';
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
    const exifData = await getRawExif(receivedFile, fileTypeInfo);
    if (!exifData) {
        return { location: NULL_LOCATION, creationTime: null };
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
}

export async function updateFileCreationDateInEXIF(
    fileBlob: Blob,
    updatedDate: Date
) {
    try {
        const fileURL = URL.createObjectURL(fileBlob);
        let imageDataURL = await convertImageToDataURL(fileURL);
        imageDataURL =
            'data:image/jpeg;base64' +
            imageDataURL.slice(imageDataURL.indexOf(','));
        const exifObj = piexif.load(imageDataURL);
        if (!exifObj['Exif']) {
            exifObj['Exif'] = {};
        }
        exifObj['Exif'][piexif.ExifIFD.DateTimeOriginal] =
            convertToExifDateFormat(updatedDate);

        const exifBytes = piexif.dump(exifObj);
        const exifInsertedFile = piexif.insert(exifBytes, imageDataURL);
        return dataURIToBlob(exifInsertedFile);
    } catch (e) {
        logError(e, 'updateFileModifyDateInEXIF failed');
        return fileBlob;
    }
}

export async function convertImageToDataURL(url: string) {
    const blob = await fetch(url).then((r) => r.blob());
    const dataUrl = await new Promise<string>((resolve) => {
        const reader = new FileReader();
        reader.onload = () => resolve(reader.result as string);
        reader.readAsDataURL(blob);
    });
    return dataUrl;
}

function dataURIToBlob(dataURI) {
    // convert base64 to raw binary data held in a string
    // doesn't handle URLEncoded DataURIs - see SO answer #6850276 for code that does this
    const byteString = atob(dataURI.split(',')[1]);

    // separate out the mime component
    const mimeString = dataURI.split(',')[0].split(':')[1].split(';')[0];

    // write the bytes of the string to an ArrayBuffer
    const ab = new ArrayBuffer(byteString.length);

    // create a view into the buffer
    const ia = new Uint8Array(ab);

    // set the bytes of the buffer to the correct values
    for (let i = 0; i < byteString.length; i++) {
        ia[i] = byteString.charCodeAt(i);
    }

    // write the ArrayBuffer to a blob, and you're done
    const blob = new Blob([ab], { type: mimeString });
    return blob;
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

function convertToExifDateFormat(date: Date) {
    return `${date.getFullYear()}:${
        date.getMonth() + 1
    }:${date.getDate()} ${date.getHours()}:${date.getMinutes()}:${date.getSeconds()}`;
}
