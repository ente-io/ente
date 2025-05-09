import { nameAndExtension } from "ente-base/file-name";
import log from "ente-base/log";

/**
 * Try to extract a date (as epoch microseconds) from a file name by matching it
 * against certain known patterns for media files.
 *
 * This uses all sorts of arbitrary heuristics gathered over time from feedback
 * by users. In particular, this is meant to capture the dates from screenshots
 * and chat app forwards.
 *
 * If the filename doesn't match a known pattern, or if there is some error
 * during the parsing, return `undefined`.
 */
export const tryParseEpochMicrosecondsFromFileName = (
    fileName: string,
): number | undefined => {
    try {
        return parseEpochMicrosecondsFromFileName(fileName);
    } catch (e) {
        log.error(`Could not extract date from file name ${fileName}`, e);
        return undefined;
    }
};

// Not sure why we have a try catch, but until there is a chance to validate
// that it doesn't indeed throw, keep this actual logic into this separate and
// more readable function.
const parseEpochMicrosecondsFromFileName = (fileName: string) => {
    let date: Date | undefined;

    fileName = fileName.trim();

    // Known patterns.
    if (fileName.startsWith("IMG-") || fileName.startsWith("VID-")) {
        // WhatsApp media files
        // - e.g. "IMG-20171218-WA0028.jpg"
        const p = fileName.split("-");
        const dateString = p[1];
        if (dateString) {
            date = parseDateFromFusedDateString(dateString);
        }
    } else if (fileName.startsWith("Screenshot_")) {
        // Screenshots on Android
        // - e.g. "Screenshot_20181227-152914.jpg"
        const dateString = fileName.replace("Screenshot_", "");
        date = parseDateFromFusedDateString(dateString);
    } else if (fileName.startsWith("signal-")) {
        // Signal images
        //
        // Signal Android uses "yyyy-MM-dd-HH-mm-ss-SSS"
        // https://github.com/signalapp/Signal-Android/commit/39e14e922bf3f5f11b796455355f69e2189d482f
        //
        // e.g. "signal-2024-08-17-21-58-10-982-1.jpg"
        //
        // Signal Desktop uses "YYYY-MM-DD-HHmmss"
        // https://github.com/signalapp/Signal-Desktop/blob/41216f1378899709d03507649e4a602cebb0d064/js/views/attachment_view.js#L97
        //
        // e.g. "signal-2018-08-21-100217.jpg"
        //
        const p = fileName.split("-");
        if (p.length > 5) {
            const dateString = `${p[1]}${p[2]}${p[3]}-${p[4]}${p[5]}${p[6]}`;
            date = parseDateFromFusedDateString(dateString);
        } else if (p.length > 1) {
            const dateString = `${p[1]}${p[2] ?? ""}${p[3] ?? ""}-${p[4] ?? ""}`;
            date = parseDateFromFusedDateString(dateString);
        }
    }

    if (!date) {
        const [name] = nameAndExtension(fileName);

        if (name.endsWith("_iOS")) {
            // Parse (some) iOS filenames.
            //
            // As reported by a customer, iOS sometimes (unknown exactly when)
            // does not retain the Exif date but instead puts it in the filename
            // in a format like `20230427_145116000_iOS.jpg`, and that Apple
            // Photos can parse it back from there.
            //
            // I couldn't find more official documentation from a quick look,
            // but there do seem to be other people on the internet
            // corraborating this:
            //
            // > iOS 11, (older versions do the same thing), when I take a photo
            // > or video, the filename consists of the following:
            // > 20170923_220934000_iOS ... file name is based on UTC/GMT time.
            // >
            // > https://discussions.apple.com/thread/8087977

            const p = name.split("_");
            if (p.length == 3) {
                const dateString = `${p[0]}-${p[1]}`;
                date = parseDateFromFusedDateString(dateString);
            }
        }
    }

    // Generic pattern.
    if (!date) {
        date = parseDateFromDigitGroups(fileName);
    }

    // Ignore invalid.
    if (!date || isNaN(date.getTime())) {
        return undefined;
    }

    // Convert to epoch microseconds.
    const unixTime = date.getTime() * 1000;
    if (unixTime === Date.UTC(0, 0, 0, 0, 0, 0, 0) || unixTime === 0) {
        // Ignore dateTimeStrings of the form "0000:00:00 00:00:00". We do
        // encounter such missing data in the wild.
        return undefined;
    } else if (unixTime > Date.now() * 1000) {
        // We shouldn't be ignoring future dates, but since this is a file name
        // parser, a future date usually indicates that we parsed some unrelated
        // number that shouldn't have been parsed.
        return undefined;
    } else {
        return unixTime;
    }
};

/**
 * An intermediate data structure we use for the functions in this file. It
 * stores the various components of a JavaScript date.
 *
 * In particular, the month is 0-indexed, as it is for the JavaScript Date's
 * `getMonth`.
 */
interface DateComponents {
    year: number;
    month: number;
    day: number;
    hour: number;
    minute: number;
    second: number;
}

/**
 * Parse a date from a string of the form "YYYYMMDD-HHMMSS". Any extra
 * characters at the end are ignored.
 */
const parseDateFromFusedDateString = (s: string) =>
    validateAndGetDateFromComponents({
        year: Number(s.slice(0, 4)),
        // JavaScript Date's month is 0-indexed.
        month: Number(s.slice(4, 6)) - 1,
        day: Number(s.slice(6, 8)),
        hour: Number(s.slice(9, 11)),
        minute: Number(s.slice(11, 13)),
        second: Number(s.slice(13, 15)),
    });

/**
 * Try to see if we can parse an date from a string with arbitrary separators.
 *
 * For example, consider a string like "2018-08-19 12:34:45". We see if it is
 * possible to extract six symbol separated digit groups from the string. If so,
 * we use them to form a date.
 */
export const parseDateFromDigitGroups = (s: string) => {
    const [year, month, day, hour, minute, second] = s.match(/\d+/g) ?? [];

    // If the filename has 8 consecutive and then 6 consecutive digits, then
    // there is a high possibility that it is a date of the form
    // "YYYYMMDD-HHMMSS".
    if (year?.length == 8 && month?.length == 6) {
        return parseDateFromFusedDateString(year + "-" + month);
    }

    return validateAndGetDateFromComponents({
        year: Number(year),
        // JavaScript Date's month is 0-indexed.
        month: Number(month) - 1,
        day: Number(day),
        hour: Number(hour),
        minute: Number(minute),
        second: Number(second),
    });
};

const validateAndGetDateFromComponents = (components: DateComponents) => {
    let date = dateFromComponents(components);
    if (hasTimeValues(components) && !isTimePartValid(date, components)) {
        // If the date has time values but they are not valid then remove them.
        date = dateFromComponents({
            ...components,
            hour: 0,
            minute: 0,
            second: 0,
        });
    }
    if (!isDatePartValid(date, components)) {
        return undefined;
    }
    if (
        date.getFullYear() < 1990 ||
        date.getFullYear() > new Date().getFullYear() + 1
    ) {
        return undefined;
    }
    return date;
};

const isDatePartValid = (date: Date, { year, month, day }: DateComponents) =>
    date.getFullYear() === year &&
    date.getMonth() === month &&
    date.getDate() === day;

const isTimePartValid = (
    date: Date,
    { hour, minute, second }: DateComponents,
) =>
    date.getHours() === hour &&
    date.getMinutes() === minute &&
    date.getSeconds() === second;

const dateFromComponents = (dateComponents: DateComponents) => {
    const { year, month, day, hour, minute, second } = dateComponents;
    if (hasTimeValues(dateComponents)) {
        return new Date(year, month, day, hour, minute, second);
    } else {
        return new Date(year, month, day);
    }
};

const hasTimeValues = ({ hour, minute, second }: DateComponents) =>
    !isNaN(hour) && !isNaN(minute) && !isNaN(second);
