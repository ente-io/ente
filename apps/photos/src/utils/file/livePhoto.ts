import { FILE_TYPE } from 'constants/file';
import { getFileExtension } from 'utils/file';

const IMAGE_EXTENSIONS = [
    'heic',
    'heif',
    'jpeg',
    'jpg',
    'png',
    'gif',
    'bmp',
    'tiff',
    'webp',
];

const VIDEO_EXTENSIONS = [
    'mov',
    'mp4',
    'm4v',
    'avi',
    'wmv',
    'flv',
    'mkv',
    'webm',
    '3gp',
    '3g2',
    'avi',
    'ogv',
    'mpg',
    'mp',
];

export function getFileTypeFromExtensionForLivePhotoClustering(
    filename: string
) {
    const extension = getFileExtension(filename)?.toLowerCase();
    if (IMAGE_EXTENSIONS.includes(extension)) {
        return FILE_TYPE.IMAGE;
    } else if (VIDEO_EXTENSIONS.includes(extension)) {
        return FILE_TYPE.VIDEO;
    }
}
