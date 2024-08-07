/** @file Dealing with the JSON metadata in Google Takeouts */

import { ensureElectron } from "@/base/electron";
import { nameAndExtension } from "@/base/file";
import log from "@/base/log";
import type { UploadItem } from "@/new/photos/services/upload/types";
import { NULL_LOCATION } from "@/new/photos/services/upload/types";
import type { Location } from "@/new/photos/types/metadata";
import { readStream } from "@/new/photos/utils/native-stream";

export interface ParsedMetadataJSON {
    creationTime: number;
    modificationTime: number;
    latitude: number;
    longitude: number;
}

export const MAX_FILE_NAME_LENGTH_GOOGLE_EXPORT = 46;

export const getMetadataJSONMapKeyForJSON = (
    collectionID: number,
    jsonFileName: string,
) => {
    let title = jsonFileName.slice(0, -1 * ".json".length);
    const endsWithNumberedSuffixWithBrackets = title.match(/\(\d+\)$/);
    if (endsWithNumberedSuffixWithBrackets) {
        title = title.slice(
            0,
            -1 * endsWithNumberedSuffixWithBrackets[0].length,
        );
        const [name, extension] = nameAndExtension(title);
        return `${collectionID}-${name}${endsWithNumberedSuffixWithBrackets[0]}.${extension}`;
    }
    return `${collectionID}-${title}`;
};

// if the file name is greater than MAX_FILE_NAME_LENGTH_GOOGLE_EXPORT(46) , then google photos clips the file name
// so we need to use the clipped file name to get the metadataJSON file
export const getClippedMetadataJSONMapKeyForFile = (
    collectionID: number,
    fileName: string,
) => {
    return `${collectionID}-${fileName.slice(
        0,
        MAX_FILE_NAME_LENGTH_GOOGLE_EXPORT,
    )}`;
};

export const getMetadataJSONMapKeyForFile = (
    collectionID: number,
    fileName: string,
) => {
    return `${collectionID}-${getFileOriginalName(fileName)}`;
};

const EDITED_FILE_SUFFIX = "-edited";

/*
    Get the original file name for edited file to associate it to original file's metadataJSON file
    as edited file doesn't have their own metadata file
*/
function getFileOriginalName(fileName: string) {
    let originalName: string = null;
    const [name, extension] = nameAndExtension(fileName);

    const isEditedFile = name.endsWith(EDITED_FILE_SUFFIX);
    if (isEditedFile) {
        originalName = name.slice(0, -1 * EDITED_FILE_SUFFIX.length);
    } else {
        originalName = name;
    }
    if (extension) {
        originalName += "." + extension;
    }
    return originalName;
}

/** Try to parse the contents of a metadata JSON file from a Google Takeout. */
export const tryParseTakeoutMetadataJSON = async (
    uploadItem: UploadItem,
): Promise<ParsedMetadataJSON | undefined> => {
    try {
        return parseMetadataJSONText(await uploadItemText(uploadItem));
    } catch (e) {
        log.error("Failed to parse takeout metadata JSON", e);
        return undefined;
    }
};

const uploadItemText = async (uploadItem: UploadItem) => {
    if (uploadItem instanceof File) {
        return await uploadItem.text();
    } else if (typeof uploadItem == "string") {
        return await ensureElectron().fs.readTextFile(uploadItem);
    } else if (Array.isArray(uploadItem)) {
        const { response } = await readStream(ensureElectron(), uploadItem);
        return await response.text();
    } else {
        return await uploadItem.file.text();
    }
};

const NULL_PARSED_METADATA_JSON: ParsedMetadataJSON = {
    creationTime: null,
    modificationTime: null,
    ...NULL_LOCATION,
};

const parseMetadataJSONText = (text: string) => {
    const metadataJSON: object = JSON.parse(text);
    if (!metadataJSON) {
        return undefined;
    }

    const parsedMetadataJSON = { ...NULL_PARSED_METADATA_JSON };

    // The metadata provided by Google does not include the time zone where the
    // photo was taken, it only has an epoch seconds value.
    if (
        metadataJSON["photoTakenTime"] &&
        metadataJSON["photoTakenTime"]["timestamp"]
    ) {
        parsedMetadataJSON.creationTime =
            metadataJSON["photoTakenTime"]["timestamp"] * 1e6;
    } else if (
        metadataJSON["creationTime"] &&
        metadataJSON["creationTime"]["timestamp"]
    ) {
        parsedMetadataJSON.creationTime =
            metadataJSON["creationTime"]["timestamp"] * 1e6;
    }
    if (
        metadataJSON["modificationTime"] &&
        metadataJSON["modificationTime"]["timestamp"]
    ) {
        parsedMetadataJSON.modificationTime =
            metadataJSON["modificationTime"]["timestamp"] * 1e6;
    }

    let locationData: Location = { ...NULL_LOCATION };
    if (
        metadataJSON["geoData"] &&
        (metadataJSON["geoData"]["latitude"] !== 0.0 ||
            metadataJSON["geoData"]["longitude"] !== 0.0)
    ) {
        locationData = metadataJSON["geoData"];
    } else if (
        metadataJSON["geoDataExif"] &&
        (metadataJSON["geoDataExif"]["latitude"] !== 0.0 ||
            metadataJSON["geoDataExif"]["longitude"] !== 0.0)
    ) {
        locationData = metadataJSON["geoDataExif"];
    }
    if (locationData !== null) {
        parsedMetadataJSON.latitude = locationData.latitude;
        parsedMetadataJSON.longitude = locationData.longitude;
    }
    return parsedMetadataJSON;
};

/**
 * Return the matching entry (if any) from {@link parsedMetadataJSONMap} for the
 * {@link fileName} and {@link collectionID} combination.
 */
export const matchTakeoutMetadata = (
    fileName: string,
    collectionID: number,
    parsedMetadataJSONMap: Map<string, ParsedMetadataJSON>,
) => {
    let key = getMetadataJSONMapKeyForFile(collectionID, fileName);
    let takeoutMetadata = parsedMetadataJSONMap.get(key);

    if (!takeoutMetadata && key.length > MAX_FILE_NAME_LENGTH_GOOGLE_EXPORT) {
        key = getClippedMetadataJSONMapKeyForFile(collectionID, fileName);
        takeoutMetadata = parsedMetadataJSONMap.get(key);
    }

    return takeoutMetadata;
};
