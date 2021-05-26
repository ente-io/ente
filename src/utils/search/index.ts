import { Suggestion, SuggestionType } from 'components/SearchBar';
import { File } from 'services/fileService';

export function getFilesInsideBbox(
    files: File[],
    bbox: [number, number, number, number]
) {
    return files.filter((file) => {
        if (file.metadata.latitude == null && file.metadata.longitude == null) {
            return false;
        }
        if (
            file.metadata.longitude >= bbox[0] &&
            file.metadata.latitude >= bbox[1] &&
            file.metadata.longitude <= bbox[2] &&
            file.metadata.latitude <= bbox[3]
        ) {
            return true;
        }
    });
}

const isSameDay = (baseDate) => (compareDate) => {
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
