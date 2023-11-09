// import { PAGES } from 'constants/pages';
// import { runningInBrowser } from 'utils/common';
// import { getAlbumsURL, getAuthURL } from 'utils/common/apiUtil';

export enum APPS {
    PHOTOS = 'PHOTOS',
    AUTH = 'AUTH',
    ALBUMS = 'ALBUMS',
}

export enum APP_ENV {
    DEVELOPMENT = 'development',
    PRODUCTION = 'production',
    TEST = 'test',
}

export const CLIENT_PACKAGE_NAMES = new Map([
    [APPS.ALBUMS, 'io.ente.albums.web'],
    [APPS.PHOTOS, 'io.ente.photos.web'],
    [APPS.AUTH, 'io.ente.auth.web'],
]);

export const APP_TITLES = new Map([
    [APPS.ALBUMS, 'Albums'],
    [APPS.PHOTOS, 'Photos'],
    [APPS.AUTH, 'Auth'],
]);
