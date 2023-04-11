import {
    EXIFLESS_FORMATS,
    EXIF_LIBRARY_UNSUPPORTED_FORMATS,
    NULL_LOCATION,
} from 'constants/upload';
import { Location } from 'types/upload';
import exifr from 'exifr';
import piexif from 'piexifjs';
import { FileTypeInfo } from 'types/upload';
import { logError } from 'utils/sentry';
import { getUnixTimeInMicroSeconds } from 'utils/time';
import { CustomError } from 'utils/error';

type ParsedEXIFData = Record<string, any> &
    Partial<{
        DateTimeOriginal: Date;
        CreateDate: Date;
        ModifyDate: Date;
        latitude: number;
        longitude: number;
    }>;

type RawEXIFData = Record<string, any> &
    Partial<{
        DateTimeOriginal: string;
        CreateDate: string;
        ModifyDate: string;
        latitude: number;
        longitude: number;
    }>;

export async function getParsedExifData(
    receivedFile: File,
    fileTypeInfo: FileTypeInfo,
    tags?: string[]
): Promise<Partial<ParsedEXIFData>> {
    try {
        const exifData: RawEXIFData = await exifr.parse(receivedFile, {
            reviveValues: false,
            pick: tags,
        });
        return parseExifData(exifData);
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
        throw e;
    }
}

function parseExifData(exifData: RawEXIFData): ParsedEXIFData {
    if (!exifData) {
        throw new Error(CustomError.EXIF_DATA_NOT_FOUND);
    }
    const { DateTimeOriginal, CreateDate, ModifyDate, ...rest } = exifData;
    const parsedExif: ParsedEXIFData = { ...rest };
    if (DateTimeOriginal) {
        parsedExif.DateTimeOriginal = parseEXIFDate(exifData.DateTimeOriginal);
    }
    if (CreateDate) {
        parsedExif.CreateDate = parseEXIFDate(exifData.CreateDate);
    }
    if (ModifyDate) {
        parsedExif.ModifyDate = parseEXIFDate(exifData.ModifyDate);
    }
    return parsedExif;
}

// can be '2009-09-23 17:40:52 UTC', '2010:07:06 20:45:12', or '2009-09-23 11:40:52-06:00'
function parseEXIFDate(dataTimeString: string) {
    try {
        if (typeof dataTimeString !== 'string') {
            throw Error(CustomError.NOT_A_DATE);
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
        if (Number.isNaN(+date)) {
            throw Error(CustomError.NOT_A_DATE);
        }
        return date;
    } catch (e) {
        logError(e, 'parseEXIFDate failed', {
            dataTimeString,
        });
        return null;
    }
}

export function getEXIFLocation(exifData: ParsedEXIFData): Location {
    if (!exifData.latitude || !exifData.longitude) {
        return NULL_LOCATION;
    }
    return { latitude: exifData.latitude, longitude: exifData.longitude };
}

export function getEXIFTime(exifData: ParsedEXIFData): number {
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

function convertToExifDateFormat(date: Date) {
    return `${date.getFullYear()}:${
        date.getMonth() + 1
    }:${date.getDate()} ${date.getHours()}:${date.getMinutes()}:${date.getSeconds()}`;
}
