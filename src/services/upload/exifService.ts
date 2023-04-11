import {
    EXIFLESS_FORMATS,
    EXIF_LIBRARY_UNSUPPORTED_FORMATS,
    NULL_EXTRACTED_METADATA,
    NULL_LOCATION,
} from 'constants/upload';
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

export async function getImageMetadata(
    receivedFile: File | ElectronFile,
    fileTypeInfo: FileTypeInfo
): Promise<ParsedExtractedMetadata> {
    let imageMetadata = NULL_EXTRACTED_METADATA;
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
        const exifData = await getParsedExifData(
            receivedFile,
            fileTypeInfo,
            EXIF_TAGS_NEEDED
        );
        if (!exifData) {
            return imageMetadata;
        }
        imageMetadata = {
            location: getEXIFLocation(exifData),
            creationTime: getEXIFTime(exifData),
        };
    } catch (e) {
        logError(e, 'getExifData failed');
    }
    return imageMetadata;
}

export async function getParsedExifData(
    receivedFile: File,
    fileTypeInfo: FileTypeInfo,
    tags?: string[]
) {
    try {
        const exifData = await exifr.parse(receivedFile, {
            reviveValues: false,
            pick: tags,
        });
        console.log('raw exif data: ', exifData);
        const parsedExif = parseExifData(exifData);
        console.log('parsed exif data: ', parsedExif);

        return parsedExif;
    } catch (e) {
        if (!EXIFLESS_FORMATS.includes(fileTypeInfo.mimeType)) {
            if (
                EXIF_LIBRARY_UNSUPPORTED_FORMATS.includes(fileTypeInfo.mimeType)
            ) {
                logError(e, 'exif library unsupported format', {
                    fileType: fileTypeInfo.exactType,
                });
            } else {
                logError(e, 'get parsed exif data failed', {
                    fileType: fileTypeInfo.exactType,
                });
            }
        }
    }
}

function parseExifData(exifData: Record<string, any>) {
    const parsedExif = {
        ...exifData,
    };
    if (exifData.DateTimeOriginal) {
        parsedExif.DateTimeOriginal = parseEXIFDate(exifData.DateTimeOriginal);
    }
    if (exifData.CreateDate) {
        parsedExif.CreateDate = parseEXIFDate(exifData.CreateDate);
    }
    if (exifData.ModifyDate) {
        parsedExif.ModifyDate = parseEXIFDate(exifData.ModifyDate);
    }
    return parsedExif;
}

// can be '2009-09-23 17:40:52 UTC', '2010:07:06 20:45:12', or '2009-09-23 11:40:52-06:00'
function parseEXIFDate(dataTimeString: string) {
    try {
        if (typeof dataTimeString !== 'string') {
            throw new Error(CustomError.NOT_A_DATE);
        }
        // attempt to parse using Date constructor
        const parsedDate = new Date(dataTimeString);
        if (!Number.isNaN(+parsedDate)) {
            return parsedDate;
        }

        // eslint-disable-next-line @typescript-eslint/no-unused-vars
        const [_, year, month, day, hours, minutes, seconds] =
            /^(\d{4})[-:](\d{2})[-:](\d{2})\s(\d{2}):(\d{2}):(\d{2})/
                .exec(dataTimeString)
                .map((x) => parseInt(x, 10));

        const date = new Date(year, month - 1, day);
        if (
            !Number.isNaN(hours) &&
            !Number.isNaN(minutes) &&
            !Number.isNaN(seconds)
        ) {
            date.setUTCHours(hours);
            date.setUTCMinutes(minutes);
            date.setUTCSeconds(seconds);
        }
        return date;
    } catch (e) {
        logError(e, 'parseEXIFDate failed', {
            dataTimeString,
        });
        return null;
    }
}

export function getEXIFLocation(exifData): Location {
    if (!exifData.latitude || !exifData.longitude) {
        return NULL_LOCATION;
    }
    return { latitude: exifData.latitude, longitude: exifData.longitude };
}

function getEXIFTime(exifData: Exif) {
    const dateTime =
        exifData.DateTimeOriginal ?? exifData.CreateDate ?? exifData.ModifyDate;
    if (!dateTime) {
        return null;
    }
    return getUnixTimeInMicroSeconds(dateTime);
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

function convertToExifDateFormat(date: Date) {
    return `${date.getFullYear()}:${
        date.getMonth() + 1
    }:${date.getDate()} ${date.getHours()}:${date.getMinutes()}:${date.getSeconds()}`;
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
