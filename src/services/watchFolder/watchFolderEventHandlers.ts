import { ElectronFile } from 'types/upload';
import { EventQueueItem } from 'types/watchFolder';
import { logError } from 'utils/sentry';
import watchFolderService from './watchFolderService';

export async function diskFileAddedCallback(file: ElectronFile) {
    try {
        const collectionNameAndFolderPath =
            await watchFolderService.getCollectionNameAndFolderPath(file.path);

        if (!collectionNameAndFolderPath) {
            return;
        }

        const { collectionName, folderPath } = collectionNameAndFolderPath;

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
        const collectionNameAndFolderPath =
            await watchFolderService.getCollectionNameAndFolderPath(filePath);

        if (!collectionNameAndFolderPath) {
            return;
        }

        const { collectionName, folderPath } = collectionNameAndFolderPath;

        console.log('added (trash) to event queue', collectionName, filePath);

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
        const collectionNameAndFolderPath =
            await watchFolderService.getCollectionNameAndFolderPath(folderPath);
        if (!collectionNameAndFolderPath) {
            return;
        }

        const { folderPath: mappedFolderPath } = collectionNameAndFolderPath;

        if (mappedFolderPath === folderPath) {
            watchFolderService.pushTrashedDir(folderPath);
        }
    } catch (e) {
        logError(e, 'error while calling diskFolderRemovedCallback');
    }
}
