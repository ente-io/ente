import { EventEmitter } from 'eventemitter3';

// When registering event handlers,
// handle errors to avoid unhandled rejection or propogation to emit call

export enum Events {
    APP_START = 'appStart',
    LOGIN = 'login',
    LOGOUT = 'logout',
    FILE_UPLOADED = 'fileUploaded',
    LOCAL_FILES_UPDATED = 'localFilesUpdated',
}

export const eventBus = new EventEmitter<Events>();
