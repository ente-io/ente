/* eslint-disable @typescript-eslint/no-unsafe-member-access */
// TODO: Audit this file
/* eslint-disable @typescript-eslint/no-unsafe-call */
/* eslint-disable @typescript-eslint/no-unsafe-assignment */
/* eslint-disable @typescript-eslint/no-unsafe-argument */
/* eslint-disable @typescript-eslint/ban-ts-comment */
/* eslint-disable @typescript-eslint/no-base-to-string */
/* eslint-disable @typescript-eslint/restrict-template-expressions */
/* eslint-disable @typescript-eslint/dot-notation */
// @ts-nocheck
import {
    parseDateFromDigitGroups,
    tryParseEpochMicrosecondsFromFileName,
} from "ente-gallery/services/upload/date";
import {
    matchJSONMetadata,
    metadataJSONMapKeyForJSON,
} from "ente-gallery/services/upload/metadata-json";
import { groupFilesByCollectionID } from "ente-gallery/utils/file";
import {
    fileCreationTime,
    fileFileName,
    fileLocation,
} from "ente-media/file-metadata";
import { FileType } from "ente-media/file-type";
import {
    savedCollectionFiles,
    savedCollections,
} from "ente-new/photos/services/photos-fdb";
import { userDetailsSnapshot } from "ente-new/photos/services/user-details";

const DATE_TIME_PARSING_TEST_FILE_NAMES = [
    {
        fileName: "Screenshot_20220807-195908_Firefox",
        expectedDateTime: "2022-08-07 19:59:08",
    },
    {
        fileName: "Screenshot_20220507-195908",
        expectedDateTime: "2022-05-07 19:59:08",
    },
    {
        fileName: "2022-02-18 16.00.12-DCMX.png",
        expectedDateTime: "2022-02-18 16:00:12",
    },
    { fileName: "20221107_231730", expectedDateTime: "2022-11-07 23:17:30" },
    {
        fileName: "2020-11-01 02.31.02",
        expectedDateTime: "2020-11-01 02:31:02",
    },
    {
        fileName: "IMG_20210921_144423",
        expectedDateTime: "2021-09-21 14:44:23",
    },
    {
        // we don't parse the time from this format, will improve later
        fileName: "2019-10-31 155703",
        expectedDateTime: "2019-10-31 00:00:00",
        correctExpectedDateTime: "2019-10-31 15:57:03",
    },
    {
        fileName: "IMG_20210921_144423_783",
        expectedDateTime: "2021-09-21 14:44:23",
    },
    {
        fileName: "Screenshot_2022-06-21-16-51-29-164_newFormat.heic",
        expectedDateTime: "2022-06-21 16:51:29",
    },
    {
        fileName:
            "Screenshot 20221106 211633.com.google.android.apps.nbu.paisa.user.jpg",
        expectedDateTime: "2022-11-06 21:16:33",
    },
    {
        fileName: "signal-2022-12-17-15-16-04-718.jpg",
        expectedDateTime: "2022-12-17 15:16:04",
    },
];

const dateTimeParsingTestFilenames2 = [
    {
        fileName: "20170923_220934000_iOS.jpg",
        expectedDateTime: "2017-09-23 22:09:34",
    },
];

const DATE_TIME_PARSING_TEST_FILE_NAMES_MUST_FAIL = [
    "Snapchat-431959199.mp4.",
    "Snapchat-400000000.mp4",
    "Snapchat-900000000.mp4",
    "Snapchat-100-10-20-19-15-12",
];

const fileNameToJSONMappingCases = [
    {
        filename: "IMG20210211125718-edited.jpg",
        jsonFilename: "IMG20210211125718.jpg.json",
    },
    {
        filename: "IMG20210211174722.jpg",
        jsonFilename: "IMG20210211174722.jpg.json",
    },
    {
        filename: "21345678901234567890123456789012345678901234567.png",
        jsonFilename: "2134567890123456789012345678901234567890123456.json",
    },
    {
        filename: "IMG20210211174722(1).jpg",
        jsonFilename: "IMG20210211174722.jpg(1).json",
    },
    {
        filename: "IMG2021021(4455)74722(1).jpg",
        jsonFilename: "IMG2021021(4455)74722.jpg(1).json",
    },
    {
        filename: "IMG2021021.json74722(1).jpg",
        jsonFilename: "IMG2021021.json74722.jpg(1).json",
    },
    {
        filename: "IMG2021021(1)74722(1).jpg",
        jsonFilename: "IMG2021021(1)74722.jpg(1).json",
    },
    {
        filename: "IMG_1159.HEIC",
        jsonFilename: "IMG_1159.HEIC.supplemental-metadata.json",
    },
    {
        filename: "PXL_20241231_151646544.MP.jpg",
        jsonFilename: "PXL_20241231_151646544.MP.jpg.supplemental-met.json",
    },
    {
        filename: "PXL_20240827_094331806.PORTRAIT(1).jpg",
        jsonFilename: "PXL_20240827_094331806.PORTRAIT.jpg.supplement(1).json",
    },
    {
        filename: "PXL_20240506_142610305.LONG_EXPOSURE-01.COVER.jpg",
        jsonFilename: "PXL_20240506_142610305.LONG_EXPOSURE-01.COVER..json",
    },
    {
        filename: "PXL_20211120_223243932.MOTION-02.ORIGINAL.jpg",
        jsonFilename: "PXL_20211120_223243932.MOTION-02.ORIGINAL.jpg..json",
    },
    {
        filename: "20220322_205147-edited(1).jpg",
        jsonFilename: "20220322_205147.jpg.supplemental-metadata(1).json",
    },
];

export async function testUpload() {
    try {
        parseDateTimeFromFileNameTest();
        fileNameToJSONMappingTests();
    } catch (e) {
        console.log(e);
    }

    const jsonString = process.env.NEXT_PUBLIC_ENTE_TEST_EXPECTED_JSON;
    if (!jsonString) {
        console.warn(
            "Not running upload tests. Please specify the NEXT_PUBLIC_ENTE_TEST_EXPECTED_JSON to run the upload tests",
        );
        return;
    }

    const expectedState = JSON.parse(jsonString);
    if (!expectedState) throw Error("Invalid JSON");

    try {
        await totalCollectionCountCheck(expectedState);
        await collectionWiseFileCount(expectedState);
        await thumbnailGenerationFailedFilesCheck(expectedState);
        await livePhotoClubbingCheck(expectedState);
        await exifDataParsingCheck(expectedState);
        await fileDimensionExtractionCheck(expectedState);
        await googleMetadataReadingCheck(expectedState);
        totalFileCountCheck(expectedState);
    } catch (e) {
        console.log(e);
    }
}

function totalFileCountCheck(expectedState) {
    const userDetails = userDetailsSnapshot();
    if (expectedState.total_file_count === userDetails.fileCount) {
        console.log("file count check passed ✅");
    } else {
        throw Error(
            `total file count check failed ❌, expected: ${expectedState.total_file_count},  got: ${userDetails.fileCount}`,
        );
    }
}

async function totalCollectionCountCheck(expectedState) {
    const collections = await savedCollections();
    if (expectedState.collection_count === collections.length) {
        console.log("collection count check passed ✅");
    } else {
        throw Error(
            `total Collection count check failed ❌
                expected : ${expectedState.collection_count},  got: ${collections.length}`,
        );
    }
}

async function collectionWiseFileCount(expectedState) {
    const files = await savedCollectionFiles();
    const collections = await savedCollections();
    const collectionToFilesMap = groupFilesByCollectionID(files);
    const collectionIDToNameMap = new Map(
        collections.map((collection) => [collection.id, collection.name]),
    );
    const collectionNameToFileCount = new Map(
        [...collectionToFilesMap.entries()].map(([collectionID, files]) => [
            collectionIDToNameMap.get(collectionID),
            files.length,
        ]),
    );
    Object.entries(expectedState.collection_files_count).forEach(
        ([collectionName, fileCount]) => {
            if (fileCount !== collectionNameToFileCount.get(collectionName)) {
                throw Error(
                    `collectionWiseFileCount check failed ❌
                        for collection ${collectionName}
                        expected File count : ${fileCount} ,  got: ${collectionNameToFileCount.get(
                            collectionName,
                        )}`,
                );
            }
        },
    );
    console.log("collection wise file count check passed ✅");
}

async function thumbnailGenerationFailedFilesCheck(expectedState) {
    const files = await savedCollectionFiles();
    const filesWithStaticThumbnail = files.filter(
        (file) => file.metadata.hasStaticThumbnail,
    );

    const fileIDSet = new Set();
    const uniqueFilesWithStaticThumbnail = filesWithStaticThumbnail.filter(
        (file) => {
            if (fileIDSet.has(file.id)) {
                return false;
            } else {
                fileIDSet.add(file.id);
                return true;
            }
        },
    );
    const fileNamesWithStaticThumbnail =
        uniqueFilesWithStaticThumbnail.map(fileFileName);

    if (
        expectedState.thumbnail_generation_failure.count <
        uniqueFilesWithStaticThumbnail.length
    ) {
        throw Error(
            `thumbnailGenerationFailedFiles Count Check failed ❌
                expected: ${expectedState.thumbnail_generation_failure.count},  got: ${uniqueFilesWithStaticThumbnail.length}`,
        );
    }
    fileNamesWithStaticThumbnail.forEach((fileName) => {
        if (
            !expectedState.thumbnail_generation_failure.files.includes(fileName)
        ) {
            throw Error(
                `thumbnailGenerationFailedFiles Check failed ❌
                    expected: ${expectedState.thumbnail_generation_failure.files},  got: ${fileNamesWithStaticThumbnail}`,
            );
        }
    });
    console.log("thumbnail generation failure check passed ✅");
}

async function livePhotoClubbingCheck(expectedState) {
    const files = await savedCollectionFiles();
    const livePhotos = files.filter(
        (file) => file.metadata.fileType == FileType.livePhoto,
    );

    const fileIDSet = new Set();
    const uniqueLivePhotos = livePhotos.filter((file) => {
        if (fileIDSet.has(file.id)) {
            return false;
        } else {
            fileIDSet.add(file.id);
            return true;
        }
    });

    const livePhotoFileNames = uniqueLivePhotos.map(fileFileName);

    if (expectedState.live_photo.count !== livePhotoFileNames.length) {
        throw Error(
            `livePhotoClubbing Check failed ❌
                expected: ${expectedState.live_photo.count},  got: ${livePhotoFileNames.length}`,
        );
    }
    expectedState.live_photo.files.forEach((fileName) => {
        if (!livePhotoFileNames.includes(fileName)) {
            throw Error(
                `livePhotoClubbing Check failed ❌
                        expected: ${expectedState.live_photo.files},  got: ${livePhotoFileNames}`,
            );
        }
    });
    console.log("live-photo clubbing check passed ✅");
}

async function exifDataParsingCheck(expectedState) {
    const files = await savedCollectionFiles();
    Object.entries(expectedState.exif).map(([fileName, exifValues]) => {
        const matchingFile = files.find(
            (file) => fileFileName(file) == fileName,
        );
        if (!matchingFile) {
            throw Error(`exifDataParsingCheck failed , ${fileName} missing`);
        }
        if (
            exifValues["creation_time"] &&
            exifValues["creation_time"] !== fileCreationTime(matchingFile)
        ) {
            throw Error(`exifDataParsingCheck failed ❌ ,
                            for ${fileName}
                            expected: ${exifValues["creation_time"]} got: ${fileCreationTime(matchingFile)}`);
        }
        if (!exifValues["location"]) return;
        const location = fileLocation(matchingFile);
        if (
            !location ||
            Math.abs(exifValues["location"].latitude - location.latitude) > 1 ||
            Math.abs(exifValues["location"].longitude - location.longitude) > 1
        ) {
            throw Error(`exifDataParsingCheck failed ❌  ,
                            for ${fileName}
                            expected: ${JSON.stringify(exifValues["location"])}
                            got: ${location}`);
        }
    });
    console.log("exif data parsing check passed ✅");
}

async function fileDimensionExtractionCheck(expectedState) {
    const files = await savedCollectionFiles();
    Object.entries(expectedState.file_dimensions).map(
        ([fileName, dimensions]) => {
            const matchingFile = files.find(
                (file) => fileFileName(file) == fileName,
            );
            if (!matchingFile) {
                throw Error(
                    `fileDimensionExtractionCheck failed , ${fileName} missing`,
                );
            }
            if (
                dimensions["width"] &&
                dimensions["width"] !== matchingFile.pubMagicMetadata.data.w &&
                dimensions["height"] &&
                dimensions["height"] !== matchingFile.pubMagicMetadata.data.h
            ) {
                throw Error(`fileDimensionExtractionCheck failed ❌ ,
                                for ${fileName}
                                expected: ${dimensions["width"]} x ${dimensions["height"]} got: ${matchingFile.pubMagicMetadata.data.w} x ${matchingFile.pubMagicMetadata.data.h}`);
            }
        },
    );
    console.log("file dimension extraction check passed ✅");
}

async function googleMetadataReadingCheck(expectedState) {
    const files = await savedCollectionFiles();
    Object.entries(expectedState.google_import).map(([fileName, metadata]) => {
        const matchingFile = files.find(
            (file) => fileFileName(file) == fileName,
        );
        if (!matchingFile) {
            throw Error(`exifDataParsingCheck failed , ${fileName} missing`);
        }
        if (
            metadata["creation_time"] &&
            metadata["creation_time"] !== fileCreationTime(matchingFile)
        ) {
            throw Error(`googleMetadataJSON reading check failed ❌ ,
                for ${fileName}
                expected: ${metadata["creation_time"]} got: ${fileCreationTime(matchingFile)}`);
        }
        if (!metadata["location"]) return;
        const location = fileLocation(matchingFile);
        if (
            !location ||
            Math.abs(metadata["location"].latitude - location.latitude) > 1 ||
            Math.abs(metadata["location"].longitude - location.longitude) > 1
        ) {
            throw Error(`googleMetadataJSON reading check failed ❌  ,
                                for ${fileName}
                                expected: ${JSON.stringify(
                                    metadata["location"],
                                )}
                                got: ${location}`);
        }
    });
    console.log("googleMetadataJSON reading check passed ✅");
}

function parseDateTimeFromFileNameTest() {
    DATE_TIME_PARSING_TEST_FILE_NAMES.forEach(
        ({ fileName, expectedDateTime }) => {
            const dateTime = parseDateFromDigitGroups(fileName);
            const formattedDateTime = getFormattedDateTime(dateTime);
            if (formattedDateTime !== expectedDateTime) {
                throw Error(
                    `parseDateTimeFromFileNameTest failed ❌ ,
                    for ${fileName}
                    expected: ${expectedDateTime} got: ${formattedDateTime}`,
                );
            }
        },
    );

    dateTimeParsingTestFilenames2.forEach(({ fileName, expectedDateTime }) => {
        const epochMicroseconds =
            tryParseEpochMicrosecondsFromFileName(fileName);
        const formattedDateTime = getFormattedDateTime(
            new Date(epochMicroseconds / 1000),
        );
        if (formattedDateTime !== expectedDateTime) {
            throw Error(
                `parseDateTimeFromFileNameTest2 failed ❌ ,
                    for ${fileName}
                    expected: ${expectedDateTime} got: ${formattedDateTime}`,
            );
        }
    });

    DATE_TIME_PARSING_TEST_FILE_NAMES_MUST_FAIL.forEach((fileName) => {
        const dateTime = parseDateFromDigitGroups(fileName);
        if (dateTime) {
            throw Error(
                `parseDateTimeFromFileNameTest failed ❌ ,
                for ${fileName}
                expected: null got: ${dateTime}`,
            );
        }
    });
    console.log("parseDateTimeFromFileNameTest passed ✅");
}

const fileNameToJSONMappingTests = () => {
    for (const { filename, jsonFilename } of fileNameToJSONMappingCases) {
        const jsonKey = metadataJSONMapKeyForJSON(undefined, 0, jsonFilename);

        // See the docs for the file name matcher as to why it doesn't return
        // the key but instead indexes into the map for us. To test it, we
        // construct a placeholder map with a dummy entry for the expected key.

        const map = new Map([[jsonKey, {}]]);
        if (!matchJSONMetadata(undefined, 0, filename, map)) {
            throw Error(
                `fileNameToJSONMappingTests failed ❌ for ${filename} and ${jsonFilename}`,
            );
        }
    }
    console.log("fileNameToJSONMappingTests passed ✅");
};

// format: YYYY-MM-DD HH:MM:SS
function getFormattedDateTime(date: Date) {
    const year = date.getFullYear();
    const month = padZero(date.getMonth() + 1);
    const day = padZero(date.getDate());
    const hour = padZero(date.getHours());
    const minute = padZero(date.getMinutes());
    const second = padZero(date.getSeconds());

    return `${year}-${month}-${day} ${hour}:${minute}:${second}`;
}

function padZero(number: number) {
    return number < 10 ? `0${number}` : number;
}
