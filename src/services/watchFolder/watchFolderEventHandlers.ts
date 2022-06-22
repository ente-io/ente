import { ElectronFile } from 'types/upload';
import { EventQueueItem } from 'types/watchFolder';
import { logError } from 'utils/sentry';
import watchFolderService from './watchFolderService';

export async function diskFileAddedCallback(file: ElectronFile) {
    try {
        const { collectionName, folderPath } =
            (await watchFolderService.getCollectionNameAndFolderPath(
                file.path
            )) ?? {};

        if (!folderPath) {
            return;
        }

        console.log('added (upload) to event queue', collectionName, file);

        const event: EventQueueItem = {
            type: 'upload',
            collectionName,
            folderPath,
            files: [file],
        };
        watchFolderService.pushEvent(event);
    } catch (e) {
        logError(e, 'error while calling diskFileAddedCallback');
    }
}

export async function diskFileRemovedCallback(filePath: string) {
    try {
        const { collectionName, folderPath } =
            (await watchFolderService.getCollectionNameAndFolderPath(
                filePath
            )) ?? {};
        console.log('added (trash) to event queue', collectionName, filePath);

        if (!folderPath) {
            return;
        }

        const event: EventQueueItem = {
            type: 'trash',
            collectionName,
            folderPath,
            paths: [filePath],
        };
        watchFolderService.pushEvent(event);
    } catch (e) {
        logError(e, 'error while calling diskFileRemovedCallback');
    }
}

export async function diskFolderRemovedCallback(folderPath: string) {
    try {
        const { folderPath: mappedFolderPath } =
            (await watchFolderService.getCollectionNameAndFolderPath(
                folderPath
            )) ?? {};
        if (!mappedFolderPath) {
            return;
        }

        if (mappedFolderPath === folderPath) {
            watchFolderService.pushTrashedDir(folderPath);
        }
    } catch (e) {
        logError(e, 'error while calling diskFolderRemovedCallback');
    }
}
