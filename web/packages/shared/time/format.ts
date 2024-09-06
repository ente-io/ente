import i18n, { t } from "i18next";

const dateTimeFullFormatter1 = new Intl.DateTimeFormat(i18n.language, {
    weekday: "short",
    month: "short",
    day: "numeric",
});

const dateTimeFullFormatter2 = new Intl.DateTimeFormat(i18n.language, {
    year: "numeric",
});

const timeFormatter = new Intl.DateTimeFormat(i18n.language, {
    timeStyle: "short",
});

function formatDateFull(date: number | Date) {
    return [dateTimeFullFormatter1, dateTimeFullFormatter2]
        .map((f) => f.format(date))
        .join(" ");
}

export function formatDate(date: number | Date) {
    const withinYear =
        new Date().getFullYear() === new Date(date).getFullYear();
    const dateTimeFormat2 = !withinYear ? dateTimeFullFormatter2 : null;
    return [dateTimeFullFormatter1, dateTimeFormat2]
        .filter((f): f is Intl.DateTimeFormat => !!f)
        .map((f) => f.format(date))
        .join(" ");
}

export function formatTime(date: number | Date) {
    return timeFormatter.format(date).toUpperCase();
}

export function formatDateTimeFull(dateTime: number | Date): string {
    return [formatDateFull(dateTime), t("at"), formatTime(dateTime)].join(" ");
}

export function formatDateTime(dateTime: number | Date): string {
    return [formatDate(dateTime), t("at"), formatTime(dateTime)].join(" ");
}
