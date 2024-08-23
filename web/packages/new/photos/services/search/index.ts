import { nullToUndefined } from "@/utils/transform";
import type { Component } from "chrono-node";
import * as chrono from "chrono-node";
import type { SearchDateComponents } from "./types";

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
export const parseDateComponents = (
    s: string,
): { components: SearchDateComponents; formattedDate: string }[] =>
    chrono.parse(s).map((result) => {
        const p = result.start;
        const component = (s: Component) =>
            p.isCertain(s) ? nullToUndefined(p.get(s)) : undefined;

        const year = component("year");
        const month = component("month");
        const day = component("day");

        const format: Intl.DateTimeFormatOptions = {};
        if (year) format.year = "numeric";
        if (month !== undefined) format.month = "long";
        if (day) format.day = "numeric";

        const formatter = new Intl.DateTimeFormat(undefined, format);
        const formattedDate = formatter.format(p.date());
        return { components: { year, month, day }, formattedDate };
    });
