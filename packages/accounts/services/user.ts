import InMemoryStore from '@ente/shared/storage/InMemoryStore';
import { _logout } from '../api/user';
import { PAGES } from '../constants/pages';
import { clearKeys } from '@ente/shared/storage/sessionStorage';
import { clearData } from '@ente/shared/storage/localStorage';
import { logError } from '@ente/shared/sentry';
import { clearFiles } from '@ente/shared/storage/localForage/helpers';
import router from 'next/router';

export const logoutUser = async () => {
    try {
        try {
            await _logout();
        } catch (e) {
            // ignore
            logError(e, 'clear InMemoryStore failed');
        }
        try {
            InMemoryStore.clear();
        } catch (e) {
            // ignore
            logError(e, 'clear InMemoryStore failed');
        }
        try {
            clearKeys();
        } catch (e) {
            logError(e, 'clearKeys failed');
        }
        try {
            clearData();
        } catch (e) {
            logError(e, 'clearData failed');
        }
        // try {
        //     await deleteAllCache();
        // } catch (e) {
        //     logError(e, 'deleteAllCache failed');
        // }
        try {
            await clearFiles();
        } catch (e) {
            logError(e, 'clearFiles failed');
        }
        // if (isElectron()) {
        //     try {
        //         safeStorageService.clearElectronStore();
        //     } catch (e) {
        //         logError(e, 'clearElectronStore failed');
        //     }
        // }
        // try {
        //     eventBus.emit(Events.LOGOUT);
        // } catch (e) {
        //     logError(e, 'Error in logout handlers');
        // }
        router.push(PAGES.ROOT);
    } catch (e) {
        logError(e, 'logoutUser failed');
    }
};
