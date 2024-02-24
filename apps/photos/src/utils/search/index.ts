import { DateValue } from "types/search";

export const isSameDayAnyYear =
    (baseDate: DateValue) => (compareDate: Date) => {
        let same = true;

        if (baseDate.month || baseDate.month === 0) {
            same = baseDate.month === compareDate.getMonth();
        }
        if (same && baseDate.date) {
            same = baseDate.date === compareDate.getDate();
        }
        if (same && baseDate.year) {
            same = baseDate.year === compareDate.getFullYear();
        }

        return same;
    };

export function getFormattedDate(date: DateValue) {
    const options = {};
    date.date && (options["day"] = "numeric");
    (date.month || date.month === 0) && (options["month"] = "long");
    date.year && (options["year"] = "numeric");
    return new Intl.DateTimeFormat("en-IN", options).format(
        new Date(date.year ?? 1, date.month ?? 1, date.date ?? 1),
    );
}
