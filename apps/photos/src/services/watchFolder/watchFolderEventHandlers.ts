import { ElectronFile } from 'types/upload';
import { EventQueueItem } from 'types/watchFolder';
import { addLogLine } from 'utils/logging';
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

        const event: EventQueueItem = {
            type: 'upload',
            collectionName,
            folderPath,
            files: [file],
        };
        watchFolderService.pushEvent(event);
        addLogLine(
            `added (upload) to event queue, collectionName:${event.collectionName} folderPath:${event.folderPath}, filesCount: ${event.files.length}`
        );
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

        const event: EventQueueItem = {
            type: 'trash',
            collectionName,
            folderPath,
            paths: [filePath],
        };
        watchFolderService.pushEvent(event);
        addLogLine(
            `added (trash) to event queue collectionName:${event.collectionName} folderPath:${event.folderPath} , pathsCount: ${event.paths.length}`
        );
    } catch (e) {
        logError(e, 'error while calling diskFileRemovedCallback');
    }
}

export async function diskFolderRemovedCallback(folderPath: string) {
    try {
        const mappings = watchFolderService.getWatchMappings();
        const mapping = mappings.find(
            (mapping) => mapping.folderPath === folderPath
        );
        if (!mapping) {
            addLogLine(`folder not found in mappings, ${folderPath}`);
            throw Error(`Watch mapping not found`);
        }
        watchFolderService.pushTrashedDir(folderPath);
        addLogLine(`added trashedDir, ${folderPath}`);
    } catch (e) {
        logError(e, 'error while calling diskFolderRemovedCallback');
    }
}
