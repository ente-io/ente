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
export function formatDateForLabel(date: Date) {
    return new Intl.DateTimeFormat('en-IN', {
        month: 'long',
        day: 'numeric',
    }).format(date);
}
