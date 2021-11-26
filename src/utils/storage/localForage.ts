import { runningInBrowser } from 'utils/common';

import localForage from 'localforage';

if (runningInBrowser()) {
    localForage.config({
        driver: localForage.INDEXEDDB,
        name: 'ente-files',
        version: 1.0,
        storeName: 'files',
    });
}

export const mlFilesStore = localForage.createInstance({
    driver: localForage.INDEXEDDB,
    name: 'ml-data',
    version: 1.0,
    storeName: 'files',
});

export const mlPeopleStore = localForage.createInstance({
    driver: localForage.INDEXEDDB,
    name: 'ml-data',
    version: 1.0,
    storeName: 'people',
});

export default localForage;
