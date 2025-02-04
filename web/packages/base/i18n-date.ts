/**
 * @file Various date formatters.
 *
 * Note that we rely on the current behaviour of a full reload on changing the
 * language. See: [Note: Changing locale causes a full reload].
 */
import i18n from "i18next";

let _relativeDateFormat: Intl.RelativeTimeFormat | undefined;

export const formatDateRelative = (date: Date) => {
    const units: [Intl.RelativeTimeFormatUnit, number][] = [
        ["year", 24 * 60 * 60 * 1000 * 365],
        ["month", (24 * 60 * 60 * 1000 * 365) / 12],
        ["day", 24 * 60 * 60 * 1000],
        ["hour", 60 * 60 * 1000],
        ["minute", 60 * 1000],
        ["second", 1000],
    ];

    const relativeDateFormat = (_relativeDateFormat ??=
        new Intl.RelativeTimeFormat(i18n.language, {
            localeMatcher: "best fit",
            numeric: "always",
            style: "short",
        }));

    // Math.abs accounts for both past and future scenarios.
    const elapsed = Math.abs(date.getTime() - Date.now());

    for (const [u, d] of units) {
        if (elapsed > d)
            return relativeDateFormat.format(Math.round(elapsed / d), u);
    }

    return relativeDateFormat.format(Math.round(elapsed / 1000), "second");
};
