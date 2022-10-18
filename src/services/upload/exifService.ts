import { NULL_EXTRACTED_METADATA, NULL_LOCATION } from 'constants/upload';
import { ElectronFile, Location } from 'types/upload';
import exifr from 'exifr';
import piexif from 'piexifjs';
import { FileTypeInfo } from 'types/upload';
import { logError } from 'utils/sentry';
import { ParsedExtractedMetadata } from 'types/upload';
import { getUnixTimeInMicroSeconds } from 'utils/time';
import { CustomError } from 'utils/error';

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

export async function getExifData(
    receivedFile: File | ElectronFile,
    fileTypeInfo: FileTypeInfo
): Promise<ParsedExtractedMetadata> {
    let parsedEXIFData = NULL_EXTRACTED_METADATA;
    try {
        if (!(receivedFile instanceof File)) {
            receivedFile = new File(
                [await receivedFile.blob()],
                receivedFile.name,
                {
                    lastModified: receivedFile.lastModified,
                }
            );
        }
        const exifData = await getRawExif(receivedFile, fileTypeInfo);
        if (!exifData) {
            return parsedEXIFData;
        }
        parsedEXIFData = {
            location: getEXIFLocation(exifData),
            creationTime: getExifTime(exifData),
        };
    } catch (e) {
        logError(e, 'getExifData failed');
    }
    return parsedEXIFData;
}

export async function updateFileCreationDateInEXIF(
    reader: FileReader,
    fileBlob: Blob,
    updatedDate: Date
) {
    try {
        let imageDataURL = await convertImageToDataURL(reader, fileBlob);
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

async function convertImageToDataURL(reader: FileReader, blob: Blob) {
    const dataURL = await new Promise<string>((resolve) => {
        reader.onload = () => resolve(reader.result as string);
        reader.readAsDataURL(blob);
    });
    return dataURL;
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

export function getEXIFLocation(exifData): Location {
    if (!exifData.latitude || !exifData.longitude) {
        return NULL_LOCATION;
    }
    return { latitude: exifData.latitude, longitude: exifData.longitude };
}

function getExifTime(exifData: Exif) {
    let dateTime =
        exifData.DateTimeOriginal ?? exifData.CreateDate ?? exifData.ModifyDate;
    if (!dateTime) {
        return null;
    }
    if (!(dateTime instanceof Date)) {
        try {
            dateTime = parseEXIFDate(dateTime);
        } catch (e) {
            logError(Error(CustomError.NOT_A_DATE), ' date revive failed', {
                dateTime,
            });
            return null;
        }
    }
    return getUnixTimeInMicroSeconds(dateTime);
}

function convertToExifDateFormat(date: Date) {
    return `${date.getFullYear()}:${
        date.getMonth() + 1
    }:${date.getDate()} ${date.getHours()}:${date.getMinutes()}:${date.getSeconds()}`;
}

function parseEXIFDate(dateTime: String) {
    const [year, month, date, hour, minute, second] = dateTime
        .match(/\d+/g)
        .map((x) => parseInt(x));
    return new Date(Date.UTC(year, month - 1, date, hour, minute, second));
}
