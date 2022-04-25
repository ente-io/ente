import { FILE_TYPE } from 'constants/file';
import { logError } from 'utils/sentry';
import { getExifData } from './exifService';
import {
    Metadata,
    ParsedMetadataJSON,
    Location,
    FileTypeInfo,
    ParsedExtractedMetadata,
    ElectronFile,
} from 'types/upload';
import { NULL_EXTRACTED_METADATA, NULL_LOCATION } from 'constants/upload';
import { splitFilenameAndExtension } from 'utils/file';
import { getVideoMetadata } from './videoMetadataService';
import { getFileNameSize } from 'utils/upload';
import { logUploadInfo } from 'utils/upload';
import {
    parseDateFromFusedDateString,
    getUnixTimeInMicroSeconds,
    tryToParseDateTime,
} from 'utils/time';

interface ParsedMetadataJSONWithTitle {
    title: string;
    parsedMetadataJSON: ParsedMetadataJSON;
}

const NULL_PARSED_METADATA_JSON: ParsedMetadataJSON = {
    creationTime: null,
    modificationTime: null,
    ...NULL_LOCATION,
};

export async function extractMetadata(
    receivedFile: File | ElectronFile,
    fileTypeInfo: FileTypeInfo
) {
    let extractedMetadata: ParsedExtractedMetadata = NULL_EXTRACTED_METADATA;
    if (fileTypeInfo.fileType === FILE_TYPE.IMAGE) {
        if (!(receivedFile instanceof File)) {
            receivedFile = new File(
                [await receivedFile.blob()],
                receivedFile.name,
                {
                    lastModified: receivedFile.lastModified,
                }
            );
        }
        extractedMetadata = await getExifData(receivedFile, fileTypeInfo);
    } else if (fileTypeInfo.fileType === FILE_TYPE.VIDEO) {
        logUploadInfo(
            `getVideoMetadata called for ${getFileNameSize(receivedFile)}`
        );
        extractedMetadata = await getVideoMetadata(receivedFile);
        logUploadInfo(
            `videoMetadata successfully extracted ${getFileNameSize(
                receivedFile
            )}`
        );
    }
    if (!extractedMetadata.creationTime) {
        extractedMetadata.creationTime = extractDateFromFileName(
            receivedFile.name
        );
    }

    const metadata: Metadata = {
        title: `${splitFilenameAndExtension(receivedFile.name)[0]}.${
            fileTypeInfo.exactType
        }`,
        creationTime:
            extractedMetadata.creationTime ?? receivedFile.lastModified * 1000,
        modificationTime: receivedFile.lastModified * 1000,
        latitude: extractedMetadata.location.latitude,
        longitude: extractedMetadata.location.longitude,
        fileType: fileTypeInfo.fileType,
    };
    return metadata;
}

export const getMetadataJSONMapKey = (
    collectionID: number,

    title: string
) => `${collectionID}-${title}`;

export async function parseMetadataJSON(
    reader: FileReader,
    receivedFile: File | ElectronFile
) {
    try {
        if (!(receivedFile instanceof File)) {
            receivedFile = new File(
                [await receivedFile.blob()],
                receivedFile.name
            );
        }
        const metadataJSON: object = await new Promise((resolve, reject) => {
            reader.onabort = () => reject(Error('file reading was aborted'));
            reader.onerror = () => reject(Error('file reading has failed'));
            reader.onload = () => {
                const result =
                    typeof reader.result !== 'string'
                        ? new TextDecoder().decode(reader.result)
                        : reader.result;
                resolve(JSON.parse(result));
            };
            reader.readAsText(receivedFile as File);
        });

        const parsedMetadataJSON: ParsedMetadataJSON =
            NULL_PARSED_METADATA_JSON;
        if (!metadataJSON || !metadataJSON['title']) {
            return;
        }

        const title = metadataJSON['title'];
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
        return { title, parsedMetadataJSON } as ParsedMetadataJSONWithTitle;
    } catch (e) {
        logError(e, 'parseMetadataJSON failed');
        // ignore
    }
}

// tries to extract date from file name if available else returns null
export function extractDateFromFileName(filename: string): number {
    filename = filename.trim();
    let parsedDate: Date;
    if (filename.startsWith('IMG-') || filename.startsWith('VID-')) {
        // Whatsapp media files
        parsedDate = parseDateFromFusedDateString(filename.split('-')[1]);
    } else if (filename.startsWith('Screenshot_')) {
        // Screenshots on droid
        parsedDate = parseDateFromFusedDateString(
            filename.replaceAll('Screenshot_', '')
        );
    } else if (filename.startsWith('signal-')) {
        // signal images
        const dateString = convertSignalNameToFusedDateString(filename);
        parsedDate = parseDateFromFusedDateString(dateString);
    } else {
        parsedDate = tryToParseDateTime(filename);
    }
    return getUnixTimeInMicroSeconds(parsedDate);
}

function convertSignalNameToFusedDateString(filename: string) {
    const dateStringParts = filename.split('-');
    return `${dateStringParts[1]}${dateStringParts[2]}${dateStringParts[3]}-${dateStringParts[4]}`;
}
