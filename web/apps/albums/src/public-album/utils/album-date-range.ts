import type { EnteFile } from "ente-media/file";
import { fileCreationPhotoDate } from "ente-media/file-metadata";
import i18n from "i18next";

// Capture dates, independent of the album's sort order, as on mobile.
export const albumCaptureDateRangeForFiles = (
    files: EnteFile[],
    locale = i18n.language === "en" ? "en-GB" : i18n.language,
) => {
    let start: Date | undefined;
    let end: Date | undefined;
    for (const file of files) {
        const date = fileCreationPhotoDate(file);
        if (!Number.isFinite(date.getTime()) || date.getTime() === 0) continue;
        if (!start || date < start) start = date;
        if (!end || date > end) end = date;
    }
    if (!start || !end) return undefined;

    const format = (date: Date, options: Intl.DateTimeFormatOptions) =>
        new Intl.DateTimeFormat(locale, options).format(date);
    const year = (date: Date) => format(date, { year: "numeric" });
    const day = (date: Date) =>
        format(date, { day: "numeric", month: "short", year: "numeric" });

    if (end.getFullYear() - start.getFullYear() >= 2) {
        return `${year(start)} – ${year(end)}`;
    }
    if (start.toDateString() === end.toDateString()) return day(start);

    // Intl keeps the range's order, month names and digits local to the reader.
    const sameMonth =
        start.getFullYear() === end.getFullYear() &&
        start.getMonth() === end.getMonth();
    return new Intl.DateTimeFormat(locale, {
        day: "numeric",
        month: "short",
        year: "numeric",
    })
        .formatRangeToParts(start, end)
        .map((part) =>
            sameMonth && part.type === "literal"
                ? part.value.replace(/\s*–\s*/g, "–")
                : part.value,
        )
        .join("");
};
