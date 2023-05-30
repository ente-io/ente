import { LocationTagData } from 'types/entity';
import { DateValue } from 'types/search';
import { Location } from 'types/upload';

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

export function isInsideLocationTag(
    location: Location,
    locationTag: LocationTagData
) {
    const { centerPoint, aSquare, bSquare } = locationTag;
    const { latitude, longitude } = location;
    const x = Math.abs(centerPoint.latitude - latitude);
    const y = Math.abs(centerPoint.longitude - longitude);
    if ((x * x) / aSquare + (y * y) / bSquare <= 1) {
        return true;
    } else {
        return false;
    }
}
