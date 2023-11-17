import { FILE_TYPE } from 'constants/file';
import { logError } from '@ente/shared/sentry';
import { getEXIFLocation, getEXIFTime, getParsedExifData } from './exifService';
import {
    Metadata,
    ParsedMetadataJSON,
    Location,
    FileTypeInfo,
    ParsedExtractedMetadata,
    ElectronFile,
    ExtractMetadataResult as ExtractMetadataResult,
} from 'types/upload';
import { NULL_EXTRACTED_METADATA, NULL_LOCATION } from 'constants/upload';
import { getVideoMetadata } from './videoMetadataService';
import {
    parseDateFromFusedDateString,
    validateAndGetCreationUnixTimeInMicroSeconds,
    tryToParseDateTime,
} from '@ente/shared/time';
import { getFileHash } from './hashService';
import { Remote } from 'comlink';
import { DedicatedCryptoWorker } from '@ente/shared/crypto/internal/crypto.worker';
import { FilePublicMagicMetadataProps } from 'types/file';
import { splitFilenameAndExtension } from 'utils/file';

const NULL_PARSED_METADATA_JSON: ParsedMetadataJSON = {
    creationTime: null,
    modificationTime: null,
    ...NULL_LOCATION,
};

const EXIF_TAGS_NEEDED = [
    'DateTimeOriginal',
    'CreateDate',
    'ModifyDate',
    'GPSLatitude',
    'GPSLongitude',
    'GPSLatitudeRef',
    'GPSLongitudeRef',
    'DateCreated',
    'ExifImageWidth',
    'ExifImageHeight',
    'ImageWidth',
    'ImageHeight',
    'PixelXDimension',
    'PixelYDimension',
    'MetadataDate',
];

export const MAX_FILE_NAME_LENGTH_GOOGLE_EXPORT = 46;

export async function extractMetadata(
    worker: Remote<DedicatedCryptoWorker>,
    receivedFile: File | ElectronFile,
    fileTypeInfo: FileTypeInfo
): Promise<ExtractMetadataResult> {
    let extractedMetadata: ParsedExtractedMetadata = NULL_EXTRACTED_METADATA;
    if (fileTypeInfo.fileType === FILE_TYPE.IMAGE) {
        extractedMetadata = await getImageMetadata(receivedFile, fileTypeInfo);
    } else if (fileTypeInfo.fileType === FILE_TYPE.VIDEO) {
        extractedMetadata = await getVideoMetadata(receivedFile);
    }
    const fileHash = await getFileHash(worker, receivedFile);

    const metadata: Metadata = {
        title: receivedFile.name,
        creationTime:
            extractedMetadata.creationTime ??
            extractDateFromFileName(receivedFile.name) ??
            receivedFile.lastModified * 1000,
        modificationTime: receivedFile.lastModified * 1000,
        latitude: extractedMetadata.location.latitude,
        longitude: extractedMetadata.location.longitude,
        fileType: fileTypeInfo.fileType,
        hash: fileHash,
    };
    const publicMagicMetadata: FilePublicMagicMetadataProps = {
        w: extractedMetadata.width,
        h: extractedMetadata.height,
    };
    return { metadata, publicMagicMetadata };
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

        imageMetadata = {
            location: getEXIFLocation(exifData),
            creationTime: getEXIFTime(exifData),
            width: exifData?.imageWidth ?? null,
            height: exifData?.imageHeight ?? null,
        };
    } catch (e) {
        logError(e, 'getExifData failed');
    }
    return imageMetadata;
}

export const getMetadataJSONMapKeyForJSON = (
    collectionID: number,
    jsonFileName: string
) => {
    let title = jsonFileName.slice(0, -1 * '.json'.length);
    const endsWithNumberedSuffixWithBrackets = title.match(/\(\d+\)$/);
    if (endsWithNumberedSuffixWithBrackets) {
        title = title.slice(
            0,
            -1 * endsWithNumberedSuffixWithBrackets[0].length
        );
        const [name, extension] = splitFilenameAndExtension(title);
        return `${collectionID}-${name}${endsWithNumberedSuffixWithBrackets[0]}.${extension}`;
    }
    return `${collectionID}-${title}`;
};

// if the file name is greater than MAX_FILE_NAME_LENGTH_GOOGLE_EXPORT(46) , then google photos clips the file name
// so we need to use the clipped file name to get the metadataJSON file
export const getClippedMetadataJSONMapKeyForFile = (
    collectionID: number,
    fileName: string
) => {
    return `${collectionID}-${fileName.slice(
        0,
        MAX_FILE_NAME_LENGTH_GOOGLE_EXPORT
    )}`;
};

export const getMetadataJSONMapKeyForFile = (
    collectionID: number,
    fileName: string
) => {
    return `${collectionID}-${getFileOriginalName(fileName)}`;
};

export async function parseMetadataJSON(receivedFile: File | ElectronFile) {
    try {
        if (!(receivedFile instanceof File)) {
            receivedFile = new File(
                [await receivedFile.blob()],
                receivedFile.name
            );
        }
        const metadataJSON: object = JSON.parse(await receivedFile.text());

        const parsedMetadataJSON: ParsedMetadataJSON =
            NULL_PARSED_METADATA_JSON;
        if (!metadataJSON) {
            return;
        }

        if (
            metadataJSON['photoTakenTime'] &&
            metadataJSON['photoTakenTime']['timestamp']
        ) {
            parsedMetadataJSON.creationTime =
                metadataJSON['photoTakenTime']['timestamp'] * 1000000;
        } else if (
            metadataJSON['creationTime'] &&
            metadataJSON['creationTime']['timestamp']
        ) {
            parsedMetadataJSON.creationTime =
                metadataJSON['creationTime']['timestamp'] * 1000000;
        }
        if (
            metadataJSON['modificationTime'] &&
            metadataJSON['modificationTime']['timestamp']
        ) {
            parsedMetadataJSON.modificationTime =
                metadataJSON['modificationTime']['timestamp'] * 1000000;
        }
        let locationData: Location = NULL_LOCATION;
        if (
            metadataJSON['geoData'] &&
            (metadataJSON['geoData']['latitude'] !== 0.0 ||
                metadataJSON['geoData']['longitude'] !== 0.0)
        ) {
            locationData = metadataJSON['geoData'];
        } else if (
            metadataJSON['geoDataExif'] &&
            (metadataJSON['geoDataExif']['latitude'] !== 0.0 ||
                metadataJSON['geoDataExif']['longitude'] !== 0.0)
        ) {
            locationData = metadataJSON['geoDataExif'];
        }
        if (locationData !== null) {
            parsedMetadataJSON.latitude = locationData.latitude;
            parsedMetadataJSON.longitude = locationData.longitude;
        }
        return parsedMetadataJSON;
    } catch (e) {
        logError(e, 'parseMetadataJSON failed');
        // ignore
    }
}

// tries to extract date from file name if available else returns null
export function extractDateFromFileName(filename: string): number {
    try {
        filename = filename.trim();
        let parsedDate: Date;
        if (filename.startsWith('IMG-') || filename.startsWith('VID-')) {
            // Whatsapp media files
            // sample name IMG-20171218-WA0028.jpg
            parsedDate = parseDateFromFusedDateString(filename.split('-')[1]);
        } else if (filename.startsWith('Screenshot_')) {
            // Screenshots on droid
            // sample name Screenshot_20181227-152914.jpg
            parsedDate = parseDateFromFusedDateString(
                filename.replaceAll('Screenshot_', '')
            );
        } else if (filename.startsWith('signal-')) {
            // signal images
            // sample name :signal-2018-08-21-100217.jpg
            const dateString = convertSignalNameToFusedDateString(filename);
            parsedDate = parseDateFromFusedDateString(dateString);
        }
        if (!parsedDate) {
            parsedDate = tryToParseDateTime(filename);
        }
        return validateAndGetCreationUnixTimeInMicroSeconds(parsedDate);
    } catch (e) {
        logError(e, 'failed to extract date From FileName ');
        return null;
    }
}

function convertSignalNameToFusedDateString(filename: string) {
    const dateStringParts = filename.split('-');
    return `${dateStringParts[1]}${dateStringParts[2]}${dateStringParts[3]}-${dateStringParts[4]}`;
}

const EDITED_FILE_SUFFIX = '-edited';

/*
    Get the original file name for edited file to associate it to original file's metadataJSON file 
    as edited file doesn't have their own metadata file
*/
function getFileOriginalName(fileName: string) {
    let originalName: string = null;
    const [nameWithoutExtension, extension] =
        splitFilenameAndExtension(fileName);

    const isEditedFile = nameWithoutExtension.endsWith(EDITED_FILE_SUFFIX);
    if (isEditedFile) {
        originalName = nameWithoutExtension.slice(
            0,
            -1 * EDITED_FILE_SUFFIX.length
        );
    } else {
        originalName = nameWithoutExtension;
    }
    if (extension) {
        originalName += '.' + extension;
    }
    return originalName;
}
