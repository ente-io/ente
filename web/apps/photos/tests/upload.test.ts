// TODO: Audit this file
/* eslint-disable @typescript-eslint/ban-ts-comment */
/* eslint-disable @typescript-eslint/restrict-template-expressions */
// @ts-nocheck
import {
    parseDateFromDigitGroups,
    tryParseEpochMicrosecondsFromFileName,
} from "ente-gallery/services/upload/date";
import {
    matchJSONMetadata,
    metadataJSONMapKeyForJSON,
} from "ente-gallery/services/upload/metadata-json";

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
    // Some exports keep the numbered suffix in the original position
    {
        filename: "skytree (2).jpg",
        jsonFilename: "skytree (2).jpg.supplemental-metadata.json",
    },
];

export function testUpload() {
    try {
        parseDateTimeFromFileNameTest();
        fileNameToJSONMappingTests();
    } catch (e) {
        console.log(e);
    }
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
