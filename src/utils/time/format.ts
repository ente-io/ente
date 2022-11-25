import constants from 'utils/strings/constants';

export function formatDateFull(date: number | Date) {
    const dateTimeFormat1 = new Intl.DateTimeFormat('en-US', {
        weekday: 'short',
        month: 'short',
        day: 'numeric',
    });

    const dateTimeFormat2 = new Intl.DateTimeFormat('en-US', {
        year: 'numeric',
    });

    return [dateTimeFormat1, dateTimeFormat2]
        .map((f) => f.format(date))
        .join(' ');
}

export function formatDate(date: number | Date) {
    const dateTimeFormat1 = new Intl.DateTimeFormat('en-US', {
        weekday: 'short',
        month: 'short',
        day: 'numeric',
    });
    const withinYear =
        new Date().getFullYear() === new Date(date).getFullYear();
    const dateTimeFormat2 = !withinYear
        ? new Intl.DateTimeFormat('en-US', {
              year: 'numeric',
          })
        : null;
    return [dateTimeFormat1, dateTimeFormat2]
        .filter((f) => !!f)
        .map((f) => f.format(date))
        .join(' ');
}

export function formatDateTimeShort(date: number | Date) {
    const dateTimeFormat = new Intl.DateTimeFormat('en-US', {
        month: 'short',
        day: 'numeric',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
    });

    return dateTimeFormat.format(date);
}

export function formatTime(date: number | Date) {
    const timeFormat = new Intl.DateTimeFormat('en-IN', {
        timeStyle: 'short',
    });
    return timeFormat.format(date).toUpperCase();
}

export function formatDateTimeFull(dateTime: number | Date): string {
    return [formatDateFull(dateTime), constants.AT, formatTime(dateTime)].join(
        ' '
    );
}

export function formatDateTime(dateTime: number | Date): string {
    return [formatDate(dateTime), constants.AT, formatTime(dateTime)].join(' ');
}

export function formatDateRelative(date: number) {
    const units = {
        year: 24 * 60 * 60 * 1000 * 365,
        month: (24 * 60 * 60 * 1000 * 365) / 12,
        day: 24 * 60 * 60 * 1000,
        hour: 60 * 60 * 1000,
        minute: 60 * 1000,
        second: 1000,
    };
    const relativeDateFormat = new Intl.RelativeTimeFormat('en-IN', {
        localeMatcher: 'best fit',
        numeric: 'always',
        style: 'long',
    });
    const elapsed = date - Date.now(); // "Math.abs" accounts for both "past" & "future" scenarios

    for (const u in units)
        if (Math.abs(elapsed) > units[u] || u === 'second')
            return relativeDateFormat.format(
                Math.round(elapsed / units[u]),
                u as Intl.RelativeTimeFormatUnit
            );
}
