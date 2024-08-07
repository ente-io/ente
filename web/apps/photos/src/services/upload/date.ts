import log from "@/base/log";

/**
 * Try to extract a date (as epoch microseconds) from a file name by matching it
 * against certain known patterns for media files.
 *
 * If it doesn't match a known pattern, or if there is some error during the
 * parsing, return `undefined`.
 */
export const tryParseEpochMicrosecondsFromFileName = (
    fileName: string,
): number | undefined => {
    try {
        fileName = fileName.trim();
        let parsedDate: Date;
        if (fileName.startsWith("IMG-") || fileName.startsWith("VID-")) {
            // WhatsApp media files
            // Sample name: IMG-20171218-WA0028.jpg
            parsedDate = parseDateFromFusedDateString(fileName.split("-")[1]);
        } else if (fileName.startsWith("Screenshot_")) {
            // Screenshots on Android
            // Sample name: Screenshot_20181227-152914.jpg
            parsedDate = parseDateFromFusedDateString(
                fileName.replaceAll("Screenshot_", ""),
            );
        } else if (fileName.startsWith("signal-")) {
            // Signal images
            // Sample name: signal-2018-08-21-100217.jpg
            const p = fileName.split("-");
            const dateString = `${p[1]}${p[2]}${p[3]}-${p[4]}`;
            parsedDate = parseDateFromFusedDateString(dateString);
        }
        if (!parsedDate) {
            parsedDate = tryToParseDateTime(fileName);
        }
        return validateAndGetCreationUnixTimeInMicroSeconds(parsedDate);
    } catch (e) {
        log.error(`Could not extract date from file name ${fileName}`, e);
        return undefined;
    }
};

export function validateAndGetCreationUnixTimeInMicroSeconds(dateTime: Date) {
    if (!dateTime || isNaN(dateTime.getTime())) {
        return null;
    }
    const unixTime = dateTime.getTime() * 1000;
    //ignoring dateTimeString = "0000:00:00 00:00:00"
    if (unixTime === Date.UTC(0, 0, 0, 0, 0, 0, 0) || unixTime === 0) {
        return null;
    } else if (unixTime > Date.now() * 1000) {
        return null;
    } else {
        return unixTime;
    }
}

interface DateComponent<T = number> {
    year: T;
    month: T;
    day: T;
    hour: T;
    minute: T;
    second: T;
}

const currentYear = new Date().getFullYear();

/*
generates data component for date in format YYYYMMDD-HHMMSS
 */
function parseDateFromFusedDateString(dateTime: string) {
    const dateComponent: DateComponent<number> = convertDateComponentToNumber({
        year: dateTime.slice(0, 4),
        month: dateTime.slice(4, 6),
        day: dateTime.slice(6, 8),
        hour: dateTime.slice(9, 11),
        minute: dateTime.slice(11, 13),
        second: dateTime.slice(13, 15),
    });
    return validateAndGetDateFromComponents(dateComponent);
}

/* sample date format = 2018-08-19 12:34:45
 the date has six symbol separated number values
 which we would extract and use to form the date
 */
export function tryToParseDateTime(dateTime: string): Date {
    const dateComponent = getDateComponentsFromSymbolJoinedString(dateTime);
    if (dateComponent.year?.length === 8 && dateComponent.month?.length === 6) {
        // the filename has size 8 consecutive and then 6 consecutive digits
        // high possibility that the it is a date in format YYYYMMDD-HHMMSS
        const possibleDateTime = dateComponent.year + "-" + dateComponent.month;
        return parseDateFromFusedDateString(possibleDateTime);
    }
    return validateAndGetDateFromComponents(
        convertDateComponentToNumber(dateComponent),
    );
}

function getDateComponentsFromSymbolJoinedString(
    dateTime: string,
): DateComponent<string> {
    const [year, month, day, hour, minute, second] =
        dateTime.match(/\d+/g) ?? [];

    return { year, month, day, hour, minute, second };
}

function validateAndGetDateFromComponents(
    dateComponent: DateComponent<number>,
    options = { minYear: 1990, maxYear: currentYear + 1 },
) {
    let date = getDateFromComponents(dateComponent);
    if (hasTimeValues(dateComponent) && !isTimePartValid(date, dateComponent)) {
        // if the date has time values but they are not valid
        // then we remove the time values and try to validate the date
        date = getDateFromComponents(removeTimeValues(dateComponent));
    }
    if (!isDatePartValid(date, dateComponent)) {
        return null;
    }
    if (
        date.getFullYear() < options.minYear ||
        date.getFullYear() > options.maxYear
    ) {
        return null;
    }
    return date;
}

function isTimePartValid(date: Date, dateComponent: DateComponent<number>) {
    return (
        date.getHours() === dateComponent.hour &&
        date.getMinutes() === dateComponent.minute &&
        date.getSeconds() === dateComponent.second
    );
}

function isDatePartValid(date: Date, dateComponent: DateComponent<number>) {
    return (
        date.getFullYear() === dateComponent.year &&
        date.getMonth() === dateComponent.month &&
        date.getDate() === dateComponent.day
    );
}

function convertDateComponentToNumber(
    dateComponent: DateComponent<string>,
): DateComponent<number> {
    return {
        year: Number(dateComponent.year),
        // https://stackoverflow.com/questions/2552483/why-does-the-month-argument-range-from-0-to-11-in-javascripts-date-constructor
        month: Number(dateComponent.month) - 1,
        day: Number(dateComponent.day),
        hour: Number(dateComponent.hour),
        minute: Number(dateComponent.minute),
        second: Number(dateComponent.second),
    };
}

function getDateFromComponents(dateComponent: DateComponent<number>) {
    const { year, month, day, hour, minute, second } = dateComponent;
    if (hasTimeValues(dateComponent)) {
        return new Date(year, month, day, hour, minute, second);
    } else {
        return new Date(year, month, day);
    }
}

function hasTimeValues(dateComponent: DateComponent<number>) {
    const { hour, minute, second } = dateComponent;
    return !isNaN(hour) && !isNaN(minute) && !isNaN(second);
}

function removeTimeValues(
    dateComponent: DateComponent<number>,
): DateComponent<number> {
    return { ...dateComponent, hour: 0, minute: 0, second: 0 };
}
