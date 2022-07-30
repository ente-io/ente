import { Bbox, DateValue } from 'types/search';
import { Location } from 'types/upload';

export function isInsideBox({ latitude, longitude }: Location, bbox: Bbox) {
    if (latitude === null && longitude === null) {
        return false;
    }
    if (
        longitude >= bbox[0] &&
        latitude >= bbox[1] &&
        longitude <= bbox[2] &&
        latitude <= bbox[3]
    ) {
        return true;
    }
}

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
    date.date && (options['day'] = 'numeric');
    (date.month || date.month === 0) && (options['month'] = 'long');
    date.year && (options['year'] = 'numeric');
    return new Intl.DateTimeFormat('en-IN', options).format(
        new Date(date.year ?? 1, date.month ?? 1, date.date ?? 1)
    );
}
