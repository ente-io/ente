export const MIN_EDITED_CREATION_TIME = new Date(1800, 0, 1);
export const MAX_EDITED_CREATION_TIME = new Date();

export const MAX_EDITED_FILE_NAME_LENGTH = 100;
export const MAX_CAPTION_SIZE = 280;
export const MAX_TRASH_BATCH_SIZE = 1000;

export const TYPE_HEIC = 'heic';
export const TYPE_HEIF = 'heif';
export const TYPE_JPEG = 'jpeg';
export const TYPE_JPG = 'jpg';

export enum FILE_TYPE {
    IMAGE,
    VIDEO,
    LIVE_PHOTO,
    OTHERS,
}

export const IMAGE_EXTENSIONS = [
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

export const VIDEO_EXTENSIONS = [
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
];
