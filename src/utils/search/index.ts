import { Suggestion, SuggestionType } from 'components/SearchBar';
import { File } from 'services/fileService';
import { Bbox } from 'services/searchService';

export function isInsideBox(
    file: { longitude: number, latitude: number },
    bbox: Bbox,
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

export const isSameDay = (baseDate) => (compareDate) => {
    return (
        baseDate.getMonth() === compareDate.getMonth() &&
        baseDate.getDate() === compareDate.getDate()
    );
};

export function getFilesWithCreationDay(files: File[], searchedDate: Date) {
    const isSearchedDate = isSameDay(searchedDate);

    return files.filter((file) =>
        isSearchedDate(new Date(file.metadata.creationTime / 1000))
    );
}
export function getFormattedDate(date: Date) {
    return new Intl.DateTimeFormat('en-IN', {
        month: 'long',
        day: 'numeric',
    }).format(date);
}

export function getDefaultSuggestions() {
    return [
        {
            label: 'Christmas',
            value: new Date(2021, 11, 25),
            type: SuggestionType.DATE,
        },
        {
            label: 'Christmas Eve',
            value: new Date(2021, 11, 24),
            type: SuggestionType.DATE,
        },
        {
            label: 'New Year',
            value: new Date(2021, 0, 1),
            type: SuggestionType.DATE,
        },
        {
            label: 'New Year Eve',
            value: new Date(2021, 11, 31),
            type: SuggestionType.DATE,
        },
        {
            label: "Valentine's Day",
            value: new Date(2021, 1, 14),
            type: SuggestionType.DATE,
        },
    ] as Suggestion[];
}
