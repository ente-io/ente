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
 */
export const parseDateComponents = (s: string): SearchDateComponents[] =>
    chrono.parse(s).map((result) => {
        const p = result.start;
        const component = (s: Component) =>
            p.isCertain(s) ? nullToUndefined(p.get(s)) : undefined;
        const year = component("year");
        const month = component("month");
        const day = component("day");
        const date = p.date();
        return { year, month, day, date };
    });
