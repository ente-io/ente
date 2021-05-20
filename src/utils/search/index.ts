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
