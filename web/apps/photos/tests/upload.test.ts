import { FILE_TYPE } from "@/media/file-type";
import { getLocalFiles } from "@/new/photos/services/files";
import { getLocalCollections } from "services/collectionService";
import { tryToParseDateTime } from "services/upload/date";
import {
    MAX_FILE_NAME_LENGTH_GOOGLE_EXPORT,
    getClippedMetadataJSONMapKeyForFile,
    getMetadataJSONMapKeyForFile,
    getMetadataJSONMapKeyForJSON,
} from "services/upload/takeout";
import { getUserDetailsV2 } from "services/userService";
import { groupFilesBasedOnCollectionID } from "utils/file";

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
    {
        fileName: "20221107_231730",
        expectedDateTime: "2022-11-07 23:17:30",
    },
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

const DATE_TIME_PARSING_TEST_FILE_NAMES_MUST_FAIL = [
    "Snapchat-431959199.mp4.",
    "Snapchat-400000000.mp4",
    "Snapchat-900000000.mp4",
    "Snapchat-100-10-20-19-15-12",
];

const FILE_NAME_TO_JSON_NAME = [
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
];

export async function testUpload() {
    const jsonString = process.env.NEXT_PUBLIC_ENTE_TEST_EXPECTED_JSON;
    if (!jsonString) {
        throw Error(
            "Please specify the NEXT_PUBLIC_ENTE_TEST_EXPECTED_JSON to run the upload tests",
        );
    }
    const expectedState = JSON.parse(jsonString);
    if (!expectedState) {
        throw Error("upload test failed expectedState missing");
    }

    try {
        await totalCollectionCountCheck(expectedState);
        await collectionWiseFileCount(expectedState);
        await thumbnailGenerationFailedFilesCheck(expectedState);
        await livePhotoClubbingCheck(expectedState);
        await exifDataParsingCheck(expectedState);
        await fileDimensionExtractionCheck(expectedState);
        await googleMetadataReadingCheck(expectedState);
        await totalFileCountCheck(expectedState);
        parseDateTimeFromFileNameTest();
        mappingFileAndJSONFileCheck();
    } catch (e) {
        console.log(e);
    }
}

async function totalFileCountCheck(expectedState) {
    const userDetails = await getUserDetailsV2();
    if (expectedState["total_file_count"] === userDetails.fileCount) {
        console.log("file count check passed ✅");
    } else {
        throw Error(
            `total file count check failed ❌, expected: ${expectedState["total_file_count"]},  got: ${userDetails.fileCount}`,
        );
    }
}

async function totalCollectionCountCheck(expectedState) {
    const collections = await getLocalCollections();
    const files = await getLocalFiles();
    const nonEmptyCollectionIds = new Set(
        files.map((file) => file.collectionID),
    );
    const nonEmptyCollections = collections.filter((collection) =>
        nonEmptyCollectionIds.has(collection.id),
    );
    if (expectedState["collection_count"] === nonEmptyCollections.length) {
        console.log("collection count check passed ✅");
    } else {
        throw Error(
            `total Collection count check failed ❌
                expected : ${expectedState["collection_count"]},  got: ${nonEmptyCollections.length}`,
        );
    }
}

async function collectionWiseFileCount(expectedState) {
    const files = await getLocalFiles();
    const collections = await getLocalCollections();
    const collectionToFilesMap = groupFilesBasedOnCollectionID(files);
    const collectionIDToNameMap = new Map(
        collections.map((collection) => [collection.id, collection.name]),
    );
    const collectionNameToFileCount = new Map(
        [...collectionToFilesMap.entries()].map(([collectionID, files]) => [
            collectionIDToNameMap.get(collectionID),
            files.length,
        ]),
    );
    Object.entries(expectedState["collection_files_count"]).forEach(
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
    const files = await getLocalFiles();
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
    const fileNamesWithStaticThumbnail = uniqueFilesWithStaticThumbnail.map(
        (file) => file.metadata.title,
    );

    if (
        expectedState["thumbnail_generation_failure"]["count"] <
        uniqueFilesWithStaticThumbnail.length
    ) {
        throw Error(
            `thumbnailGenerationFailedFiles Count Check failed ❌
                expected: ${expectedState["thumbnail_generation_failure"]["count"]},  got: ${uniqueFilesWithStaticThumbnail.length}`,
        );
    }
    fileNamesWithStaticThumbnail.forEach((fileName) => {
        if (
            !expectedState["thumbnail_generation_failure"]["files"].includes(
                fileName,
            )
        ) {
            throw Error(
                `thumbnailGenerationFailedFiles Check failed ❌
                    expected: ${expectedState["thumbnail_generation_failure"]["files"]},  got: ${fileNamesWithStaticThumbnail}`,
            );
        }
    });
    console.log("thumbnail generation failure check passed ✅");
}

async function livePhotoClubbingCheck(expectedState) {
    const files = await getLocalFiles();
    const livePhotos = files.filter(
        (file) => file.metadata.fileType === FILE_TYPE.LIVE_PHOTO,
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

    const livePhotoFileNames = uniqueLivePhotos.map(
        (file) => file.metadata.title,
    );

    if (expectedState["live_photo"]["count"] !== livePhotoFileNames.length) {
        throw Error(
            `livePhotoClubbing Check failed ❌
                expected: ${expectedState["live_photo"]["count"]},  got: ${livePhotoFileNames.length}`,
        );
    }
    expectedState["live_photo"]["files"].forEach((fileName) => {
        if (!livePhotoFileNames.includes(fileName)) {
            throw Error(
                `livePhotoClubbing Check failed ❌
                        expected: ${expectedState["live_photo"]["files"]},  got: ${livePhotoFileNames}`,
            );
        }
    });
    console.log("live-photo clubbing check passed ✅");
}

async function exifDataParsingCheck(expectedState) {
    const files = await getLocalFiles();
    Object.entries(expectedState["exif"]).map(([fileName, exifValues]) => {
        const matchingFile = files.find(
            (file) => file.metadata.title === fileName,
        );
        if (!matchingFile) {
            throw Error(`exifDataParsingCheck failed , ${fileName} missing`);
        }
        if (
            exifValues["creation_time"] &&
            exifValues["creation_time"] !== matchingFile.metadata.creationTime
        ) {
            throw Error(`exifDataParsingCheck failed ❌ ,
                            for ${fileName}
                            expected: ${exifValues["creation_time"]} got: ${matchingFile.metadata.creationTime}`);
        }
        if (
            exifValues["location"] &&
            (Math.abs(
                exifValues["location"]["latitude"] -
                    matchingFile.metadata.latitude,
            ) > 1 ||
                Math.abs(
                    exifValues["location"]["longitude"] -
                        matchingFile.metadata.longitude,
                ) > 1)
        ) {
            throw Error(`exifDataParsingCheck failed ❌  ,
                            for ${fileName}
                            expected: ${JSON.stringify(exifValues["location"])}
                            got: [${matchingFile.metadata.latitude},${
                                matchingFile.metadata.longitude
                            }]`);
        }
    });
    console.log("exif data parsing check passed ✅");
}

async function fileDimensionExtractionCheck(expectedState) {
    const files = await getLocalFiles();
    Object.entries(expectedState["file_dimensions"]).map(
        ([fileName, dimensions]) => {
            const matchingFile = files.find(
                (file) => file.metadata.title === fileName,
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
    const files = await getLocalFiles();
    Object.entries(expectedState["google_import"]).map(
        ([fileName, metadata]) => {
            const matchingFile = files.find(
                (file) => file.metadata.title === fileName,
            );
            if (!matchingFile) {
                throw Error(
                    `exifDataParsingCheck failed , ${fileName} missing`,
                );
            }
            if (
                metadata["creation_time"] &&
                metadata["creation_time"] !== matchingFile.metadata.creationTime
            ) {
                throw Error(`googleMetadataJSON reading check failed ❌ ,
                for ${fileName}
                expected: ${metadata["creation_time"]} got: ${matchingFile.metadata.creationTime}`);
            }
            if (
                metadata["location"] &&
                (Math.abs(
                    metadata["location"]["latitude"] -
                        matchingFile.metadata.latitude,
                ) > 1 ||
                    Math.abs(
                        metadata["location"]["longitude"] -
                            matchingFile.metadata.longitude,
                    ) > 1)
            ) {
                throw Error(`googleMetadataJSON reading check failed ❌  ,
                                for ${fileName}
                                expected: ${JSON.stringify(
                                    metadata["location"],
                                )}
                                got: [${matchingFile.metadata.latitude},${
                                    matchingFile.metadata.longitude
                                }]`);
            }
        },
    );
    console.log("googleMetadataJSON reading check passed ✅");
}

function parseDateTimeFromFileNameTest() {
    DATE_TIME_PARSING_TEST_FILE_NAMES.forEach(
        ({ fileName, expectedDateTime }) => {
            const dateTime = tryToParseDateTime(fileName);
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
    DATE_TIME_PARSING_TEST_FILE_NAMES_MUST_FAIL.forEach((fileName) => {
        const dateTime = tryToParseDateTime(fileName);
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

function mappingFileAndJSONFileCheck() {
    FILE_NAME_TO_JSON_NAME.forEach(({ filename, jsonFilename }) => {
        const jsonFileNameGeneratedKey = getMetadataJSONMapKeyForJSON(
            0,
            jsonFilename,
        );
        let fileNameGeneratedKey = getMetadataJSONMapKeyForFile(0, filename);
        if (
            fileNameGeneratedKey !== jsonFileNameGeneratedKey &&
            filename.length > MAX_FILE_NAME_LENGTH_GOOGLE_EXPORT
        ) {
            fileNameGeneratedKey = getClippedMetadataJSONMapKeyForFile(
                0,
                filename,
            );
        }

        if (fileNameGeneratedKey !== jsonFileNameGeneratedKey) {
            throw Error(
                `mappingFileAndJSONFileCheck failed ❌ ,
                    for ${filename}
                    expected: ${jsonFileNameGeneratedKey} got: ${fileNameGeneratedKey}`,
            );
        }
    });
    console.log("mappingFileAndJSONFileCheck passed ✅");
}

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
