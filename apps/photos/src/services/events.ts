import { EventEmitter } from 'eventemitter3';

// When registering event handlers,
// handle errors to avoid unhandled rejection or propagation to emit call

export enum Events {
    LOGOUT = 'logout',
    FILE_UPLOADED = 'fileUploaded',
    LOCAL_FILES_UPDATED = 'localFilesUpdated',
}

export const eventBus = new EventEmitter<Events>();
