import { EventEmitter } from "eventemitter3";

// TODO: Remove me

// When registering event handlers,
// handle errors to avoid unhandled rejection or propagation to emit call

export enum Events {
    LOCAL_FILES_UPDATED = "localFilesUpdated",
}

export const eventBus = new EventEmitter<Events>();
