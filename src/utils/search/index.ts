import { DateValue, Suggestion, SuggestionType } from 'components/SearchBar';
import { File } from 'services/fileService';
import { Bbox } from 'services/searchService';

export function isInsideBox(
    file: { longitude: number; latitude: number },
    bbox: Bbox
) {
    if (file.latitude == null && file.longitude == null) {
        return false;
    }
    if (
        file.longitude >= bbox[0] &&
        file.latitude >= bbox[1] &&
        file.longitude <= bbox[2] &&
        file.latitude <= bbox[3]
    ) {
        return true;
    }
}

export const isSameDay = (baseDate: DateValue) => (compareDate: Date) => {
    let same = true;

    if (baseDate.month || baseDate.month === 0) {
        same = baseDate.month === compareDate.getMonth();
    }
    if (baseDate.date) {
        same = baseDate.date === compareDate.getDate();
    }
    if (baseDate.year) {
        same = baseDate.year === compareDate.getFullYear();
    }

    return same;
};

export function getFilesWithCreationDay(
    files: File[],
    searchedDate: DateValue
) {
    const isSearchedDate = isSameDay(searchedDate);
    return files.filter((file) =>
        isSearchedDate(new Date(file.metadata.creationTime / 1000))
    );
}
export function getFormattedDate(date: DateValue) {
    var options = {};
    date.date && (options['day'] = 'numeric');
    (date.month || date.month === 0) && (options['month'] = 'long');
    date.year && (options['year'] = 'numeric');
    return new Intl.DateTimeFormat('en-IN', options).format(
        new Date(date.year ?? 1, date.month ?? 1, date.date ?? 1)
    );
}
