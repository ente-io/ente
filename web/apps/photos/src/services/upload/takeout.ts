/** @file Dealing with the JSON metadata sidecar files */

import { ensureElectron } from "@/base/electron";
import { nameAndExtension } from "@/base/file";
import log from "@/base/log";
import { type Location } from "@/base/types";
import type { UploadItem } from "@/new/photos/services/upload/types";
import { readStream } from "@/new/photos/utils/native-stream";
import { maybeParseInt } from "@/utils/parse";

/**
 * The data we read from the JSON metadata sidecar files.
 *
 * Originally these were used to read the JSON metadata sidecar files present in
 * a Google Takeout. However, during our own export, we also write out files
 * with a similar structure.
 */
export interface ParsedMetadataJSON {
    creationTime?: number;
    modificationTime?: number;
    location?: Location;
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

const parseMetadataJSONText = (text: string) => {
    const metadataJSON: object = JSON.parse(text);
    if (!metadataJSON) {
        return undefined;
    }

    const parsedMetadataJSON: ParsedMetadataJSON = {};

    parsedMetadataJSON.creationTime =
        parseGTTimestamp(metadataJSON["photoTakenTime"]) ??
        parseGTTimestamp(metadataJSON["creationTime"]);

    parsedMetadataJSON.modificationTime = parseGTTimestamp(
        metadataJSON["modificationTime"],
    );

    parsedMetadataJSON.location =
        parseGTLocation(metadataJSON["geoData"]) ??
        parseGTLocation(metadataJSON["geoDataExif"]);

    return parsedMetadataJSON;
};

/**
 * Parse a nullish epoch seconds timestamp string from a field in a Google
 * Takeout JSON, converting it into epoch microseconds if it is found.
 *
 * Note that the metadata provided by Google does not include the time zone
 * where the photo was taken, it only has an epoch seconds value. There is an
 * associated formatted date value (e.g. "17 Feb 2021, 03:22:16 UTC") but that
 * seems to be in UTC and doesn't have the time zone either.
 */
const parseGTTimestamp = (o: unknown): number | undefined => {
    if (
        o &&
        typeof o == "object" &&
        "timestamp" in o &&
        typeof o.timestamp == "string"
    ) {
        const timestamp = maybeParseInt(o.timestamp);
        if (timestamp) return timestamp * 1e6;
    }
    return undefined;
};

/**
 * Parse a (latitude, longitude) location pair field in a Google Takeout JSON.
 *
 * Apparently Google puts in (0, 0) to indicate missing data, so this function
 * only returns a parsed result if both components are present and non-zero.
 */
const parseGTLocation = (o: unknown): Location | undefined => {
    if (
        o &&
        typeof o == "object" &&
        "latitude" in o &&
        typeof o.latitude == "number" &&
        "longitude" in o &&
        typeof o.longitude == "number"
    ) {
        const { latitude, longitude } = o;
        if (latitude !== 0 || longitude !== 0) return { latitude, longitude };
    }
    return undefined;
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
