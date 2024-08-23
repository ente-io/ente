import * as chrono from "chrono-node";
import type { SearchDateComponents } from "./types";

const DIGITS = new Set(["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]);

export const parsePotentialDate = (
    humanDate: string,
): SearchDateComponents[] => {
    const date = chrono.parseDate(humanDate);
    const date1 = chrono.parseDate(`${humanDate} 1`);
    if (date !== null) {
        const dates = [
            { month: date.getMonth() },
            { date: date.getDate(), month: date.getMonth() },
        ];
        let reverse = false;
        humanDate.split("").forEach((c) => {
            if (DIGITS.has(c)) {
                reverse = true;
            }
        });
        // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
        if (reverse) {
            return dates.reverse();
        }
        return dates;
    }
    if (date1) {
        return [{ month: date1.getMonth() }];
    }
    return [];
};
