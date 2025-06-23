/**
 * @file Various date formatters.
 *
 * Note that we rely on the current behaviour of a full reload on changing the
 * language. See: [Note: Changing locale causes a full reload].
 */
import i18n, { t } from "i18next";

const _dateFormat = new Intl.DateTimeFormat(i18n.language, {
    weekday: "short",
    day: "numeric",
    month: "short",
    year: "numeric",
});

const _dateWithoutYearFormat = new Intl.DateTimeFormat(i18n.language, {
    weekday: "short",
    day: "numeric",
    month: "short",
});

const _timeFormat = new Intl.DateTimeFormat(i18n.language, {
    timeStyle: "short",
});

/**
 * Return a locale aware formatted date from the given {@link Date}.
 *
 * The behaviour depends upon whether the given {@link date} falls within the
 * current calendar year.
 *
 * - For dates in the current year, year is omitted, e.g, "Fri, 21 Feb".
 *
 * - Otherwise, the year is included, e.g., "Fri, 21 Feb 2025".
 */
export const formattedDate = (date: Date) =>
    (isSameYear(date) ? _dateWithoutYearFormat : _dateFormat).format(date);

const isSameYear = (date: Date) =>
    new Date().getFullYear() === date.getFullYear();

/**
 * Return a locale aware formatted time from the given {@link Date}.
 *
 * Example: "11:51 AM"
 */
export const formattedTime = (date: Date) => _timeFormat.format(date);

/**
 * Return a locale aware formatted date and time from the given {@link Date},
 * using the year omission behavior as documented in {@link formattedDate}.
 *
 * Example:
 * - If within year: "Fri, 21 Feb at 11:51 AM".
 * - Otherwise: "Fri, 21 Feb 2025 at 11:51 AM"
 *
 * @param dateOrEpochMicroseconds A JavaScript Date or a numeric epoch
 * microseconds value.
 *
 * [Note: Remote timestamps are epoch microseconds]
 *
 * Remote talks in terms of epoch microseconds, while JavaScript dates are
 * underlain by epoch milliseconds.
 *
 * As a convenience, this function can be either be directly passed a JavaScript
 * date, or it can be given the raw epoch microseconds value and it'll convert
 * internally.
 */
export const formattedDateTime = (dateOrEpochMicroseconds: Date | number) =>
    _formattedDateTime(toDate(dateOrEpochMicroseconds));

const _formattedDateTime = (date: Date) =>
    [formattedDate(date), t("at"), formattedTime(date)].join(" ");

const toDate = (dm: Date | number) =>
    typeof dm == "number" ? new Date(dm / 1000) : dm;

let _relativeTimeFormat: Intl.RelativeTimeFormat | undefined;

/**
 * Return a locale aware relative version of the given date.
 *
 * Example: "in 23 days"
 *
 * @param dateOrEpochMicroseconds A JavaScript Date or a numeric epoch
 * microseconds value.
 *
 * See: [Note: Remote timestamps are epoch microseconds]
 */
export const formattedDateRelative = (
    dateOrEpochMicroseconds: Date | number,
) => {
    const units: [Intl.RelativeTimeFormatUnit, number][] = [
        ["year", 24 * 60 * 60 * 1000 * 365],
        ["month", (24 * 60 * 60 * 1000 * 365) / 12],
        ["day", 24 * 60 * 60 * 1000],
        ["hour", 60 * 60 * 1000],
        ["minute", 60 * 1000],
        ["second", 1000],
    ];

    const date = toDate(dateOrEpochMicroseconds);

    // Math.abs accounts for both past and future scenarios.
    const elapsed = Math.abs(date.getTime() - Date.now());

    // Lazily created, then cached, instance of RelativeTimeFormat.
    const relativeTimeFormat = (_relativeTimeFormat ??=
        new Intl.RelativeTimeFormat(i18n.language, {
            localeMatcher: "best fit",
            numeric: "always",
            style: "short",
        }));

    for (const [u, d] of units) {
        if (elapsed > d)
            return relativeTimeFormat.format(Math.round(elapsed / d), u);
    }

    return relativeTimeFormat.format(Math.round(elapsed / 1000), "second");
};
