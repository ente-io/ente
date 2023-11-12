import { PAGES } from 'constants/pages';
import { runningInBrowser } from 'utils/common';
import { getAlbumsURL, getAuthURL } from 'utils/common/apiUtil';

export enum APPS {
    PHOTOS = 'PHOTOS',
    AUTH = 'AUTH',
    ALBUMS = 'ALBUMS',
}

export const ALLOWED_APP_PAGES = new Map([
    [APPS.ALBUMS, [PAGES.SHARED_ALBUMS, PAGES.ROOT]],
    [
        APPS.AUTH,
        [
            PAGES.ROOT,
            PAGES.LOGIN,
            PAGES.SIGNUP,
            PAGES.VERIFY,
            PAGES.CREDENTIALS,
            PAGES.RECOVER,
            PAGES.CHANGE_PASSWORD,
            PAGES.GENERATE,
            PAGES.AUTH,
            PAGES.TWO_FACTOR_VERIFY,
            PAGES.TWO_FACTOR_RECOVER,
        ],
    ],
]);

export const CLIENT_PACKAGE_NAMES = new Map([
    [APPS.ALBUMS, 'io.ente.albums.web'],
    [APPS.PHOTOS, 'io.ente.photos.web'],
    [APPS.AUTH, 'io.ente.auth.web'],
]);

export const getAppNameAndTitle = () => {
    if (!runningInBrowser()) {
        return {};
    }
    const currentURL = new URL(window.location.href);
    const albumsURL = new URL(getAlbumsURL());
    const authURL = new URL(getAuthURL());
    if (currentURL.origin === albumsURL.origin) {
        return { name: APPS.ALBUMS, title: 'ente Photos' };
    } else if (currentURL.origin === authURL.origin) {
        return { name: APPS.AUTH, title: 'ente Auth' };
    } else {
        return { name: APPS.PHOTOS, title: 'ente Photos' };
    }
};

export const getAppTitle = () => {
    return getAppNameAndTitle().title;
};

export const getAppName = () => {
    return getAppNameAndTitle().name;
};
