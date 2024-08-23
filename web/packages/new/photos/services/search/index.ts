import { nullToUndefined } from "@/utils/transform";
import type { Component } from "chrono-node";
import * as chrono from "chrono-node";
import type { SearchDateComponents } from "./types";

interface DateSearchResult {
    components: SearchDateComponents;
    formattedDate: string;
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
export const parseDateComponents = (s: string): DateSearchResult[] => {
    const result = parseChrono(s);
    if (result.length) return result;
    // chrono does not parse years like "2024", so do it manually.
    return parseYearComponents(s);
};

export const parseChrono = (s: string): DateSearchResult[] =>
    chrono.parse(s).map((result) => {
        const p = result.start;
        const component = (s: Component) =>
            p.isCertain(s) ? nullToUndefined(p.get(s)) : undefined;

        const year = component("year");
        const month = component("month");
        const day = component("day");
        const weekday = component("weekday");
        const components = { year, month, day, weekday };

        const format: Intl.DateTimeFormatOptions = {};
        if (year) format.year = "numeric";
        if (month) format.month = "long";
        if (day) format.day = "numeric";
        if (weekday) format.weekday = "long";

        const formatter = new Intl.DateTimeFormat(undefined, format);
        const formattedDate = formatter.format(p.date());
        return { components, formattedDate };
    });

/** Parse a string like "2024" into a date search result. */
const parseYearComponents = (s: string): DateSearchResult[] => {
    // s is already trimmed
    if (s.length == 4) {
        const year = parseInt(s);
        if (year > 0 && year <= 9999) {
            const components = { year };
            return [{ components, formattedDate: s }];
        }
    }
    return [];
};
