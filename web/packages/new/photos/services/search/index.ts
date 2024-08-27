import { nullToUndefined } from "@/utils/transform";
import type { Component } from "chrono-node";
import * as chrono from "chrono-node";
import i18n, { t } from "i18next";
import type { SearchDateComponents } from "./types";

interface DateSearchResult {
    components: SearchDateComponents;
    label: string;
}

/**
 * Try to parse an arbitrary search string into sets of date components.
 *
 * e.g. "December 2022" will be parsed into a
 *
 *     [(year 2022, month 12, day undefined)]
 *
 * while "22 December 2022" will be parsed into
 *
 *     [(year 2022, month 12, day 22)]
 *
 * In addition, also return a formatted representation of the "best" guess at
 * the date that was intended by the search string.
 */
export const parseDateComponents = (s: string): DateSearchResult[] =>
    parseChrono(s)
        .concat(parseYearComponents(s))
        .concat(parseHolidayComponents(s));

export const parseChrono = (s: string): DateSearchResult[] =>
    chrono
        .parse(s)
        .map((result) => {
            const p = result.start;
            const component = (s: Component) =>
                p.isCertain(s) ? nullToUndefined(p.get(s)) : undefined;

            const year = component("year");
            const month = component("month");
            const day = component("day");
            const weekday = component("weekday");
            const hour = component("hour");

            if (!year && !month && !day && !weekday && !hour) return undefined;
            const components = { year, month, day, weekday, hour };

            const format: Intl.DateTimeFormatOptions = {};
            if (year) format.year = "numeric";
            if (month) format.month = "long";
            if (day) format.day = "numeric";
            if (weekday) format.weekday = "long";
            if (hour) {
                format.hour = "numeric";
                format.dayPeriod = "short";
            }

            const formatter = new Intl.DateTimeFormat(i18n.language, format);
            const label = formatter.format(p.date());
            return { components, label };
        })
        .filter((x) => x !== undefined);

/** chrono does not parse years like "2024", so do it manually. */
const parseYearComponents = (s: string): DateSearchResult[] => {
    // s is already trimmed.
    if (s.length == 4) {
        const year = parseInt(s);
        if (year && year <= 9999) {
            const components = { year };
            return [{ components, label: s }];
        }
    }
    return [];
};

// This cannot be a const, it needs to be evaluated lazily for the t() to work.
const holidays = (): DateSearchResult[] => [
    { components: { month: 12, day: 25 }, label: t("CHRISTMAS") },
    { components: { month: 12, day: 24 }, label: t("CHRISTMAS_EVE") },
    { components: { month: 1, day: 1 }, label: t("NEW_YEAR") },
    { components: { month: 12, day: 31 }, label: t("NEW_YEAR_EVE") },
];

const parseHolidayComponents = (s: string) =>
    holidays().filter(({ label }) => label.toLowerCase().includes(s));
