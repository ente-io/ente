/**
 * @file Various date formatters.
 *
 * Note that we rely on the current behaviour of a full reload on changing the
 * language. See: [Note: Changing locale causes a full reload].
 */

import i18n from "i18next";

let _relativeDateFormat: Intl.RelativeTimeFormat | undefined;

export const formatDateRelative = (epochMilliseconds: number) => {
    const units = {
        year: 24 * 60 * 60 * 1000 * 365,
        month: (24 * 60 * 60 * 1000 * 365) / 12,
        day: 24 * 60 * 60 * 1000,
        hour: 60 * 60 * 1000,
        minute: 60 * 1000,
        second: 1000,
    };
    const relativeDateFormat = (_relativeDateFormat ??=
        new Intl.RelativeTimeFormat(i18n.language, {
            localeMatcher: "best fit",
            numeric: "always",
            style: "long",
        }));

    // "Math.abs" accounts for both past and future scenarios.
    const elapsed = Math.abs(epochMilliseconds - Date.now());

    for (const u in units)
        if (elapsed > units[u] || u === "second")
            return relativeDateFormat.format(
                Math.round(elapsed / units[u]),
                u as Intl.RelativeTimeFormatUnit,
            );
};
