/** @file Dealing with the JSON metadata in Google Takeouts */

import { ensureElectron } from "@/next/electron";
import { nameAndExtension } from "@/next/file";
import log from "@/next/log";
import type { ElectronFile } from "@/next/types/file";
import { NULL_LOCATION } from "constants/upload";
import { type Location } from "types/upload";

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

/** Try to parse the contents of a metadata JSON file in a Google Takeout. */
export const tryParseTakeoutMetadataJSON = async (
    receivedFile: File | ElectronFile | string,
): Promise<ParsedMetadataJSON | undefined> => {
    try {
        let text: string;
        if (typeof receivedFile == "string") {
            text = await ensureElectron().fs.readTextFile(receivedFile);
        } else {
            if (!(receivedFile instanceof File)) {
                receivedFile = new File(
                    [await receivedFile.blob()],
                    receivedFile.name,
                );
            }
            text = await receivedFile.text();
        }

        return parseMetadataJSONText(text);
    } catch (e) {
        log.error("Failed to parse takeout metadata JSON", e);
        return undefined;
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

    const parsedMetadataJSON: ParsedMetadataJSON = NULL_PARSED_METADATA_JSON;

    if (
        metadataJSON["photoTakenTime"] &&
        metadataJSON["photoTakenTime"]["timestamp"]
    ) {
        parsedMetadataJSON.creationTime =
            metadataJSON["photoTakenTime"]["timestamp"] * 1000000;
    } else if (
        metadataJSON["creationTime"] &&
        metadataJSON["creationTime"]["timestamp"]
    ) {
        parsedMetadataJSON.creationTime =
            metadataJSON["creationTime"]["timestamp"] * 1000000;
    }
    if (
        metadataJSON["modificationTime"] &&
        metadataJSON["modificationTime"]["timestamp"]
    ) {
        parsedMetadataJSON.modificationTime =
            metadataJSON["modificationTime"]["timestamp"] * 1000000;
    }
    let locationData: Location = NULL_LOCATION;
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
