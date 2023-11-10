import { AUTH_PAGES, PHOTOS_PAGES } from '../constants/pages';

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
    [APPS.ALBUMS, 'Ente Albums'],
    [APPS.PHOTOS, 'Ente Photos'],
    [APPS.AUTH, 'Ente Auth'],
]);

export const APP_HOMES = new Map([
    [APPS.ALBUMS, '/'],
    [APPS.PHOTOS, PHOTOS_PAGES.GALLERY],
    [APPS.AUTH, AUTH_PAGES.AUTH],
]);

export const OTT_CLIENTS = new Map([
    [APPS.PHOTOS, 'web'],
    [APPS.AUTH, 'totp'],
]);
