import exifr from 'exifr';
import piexif from 'piexifjs';
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
    const exifData = await exifr.parse(receivedFile, EXIF_TAGS_NEEDED);
    if (!exifData) {
        return { location: NULL_LOCATION, creationTime: null };
    }
    const parsedEXIFData = {
        location: getEXIFLocation(exifData),
        creationTime: getUNIXTime(exifData),
    };
    return parsedEXIFData;
}

export async function updateFileModifyDateInEXIF(
    fileBlob: Blob,
    updatedDate: Date
) {
    const fileURL = URL.createObjectURL(fileBlob);
    let imageDataURL = await convertImageToDataURL(fileURL);
    imageDataURL =
        'data:image/jpeg;base64' +
        imageDataURL.slice(imageDataURL.indexOf(','));
    const exifObj = piexif.load(imageDataURL);
    if (!exifObj['0th']) {
        exifObj['0th'] = {};
    }
    exifObj['0th'][piexif.ImageIFD.DateTime] =
        convertToExifDateFormat(updatedDate);

    const exifBytes = piexif.dump(exifObj);
    const exifInsertedFile = piexif.insert(exifBytes, imageDataURL);
    return dataURIToBlob(exifInsertedFile);
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

function convertToExifDateFormat(date: Date) {
    return `${date.getFullYear()}:${
        date.getMonth() + 1
    }:${date.getDate()} ${date.getHours()}:${date.getMinutes()}:${date.getSeconds()}`;
}
