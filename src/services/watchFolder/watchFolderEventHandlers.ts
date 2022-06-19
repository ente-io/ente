import { ElectronFile } from 'types/upload';
import { EventQueueItem } from 'types/watchFolder';
import { logError } from 'utils/sentry';
import watchFolderService from './watchFolderService';

export async function diskFileAddedCallback(file: ElectronFile) {
    try {
        const collectionName = await watchFolderService.getCollectionName(
            file.path
        );

        if (!collectionName) {
            return;
        }

        console.log('added (upload) to event queue', collectionName, file);

        const event: EventQueueItem = {
            type: 'upload',
            collectionName,
            files: [file],
        };
        watchFolderService.pushEvent(event);
    } catch (e) {
        logError(e, 'error while calling diskFileAddedCallback');
    }
}

export async function diskFileRemovedCallback(filePath: string) {
    try {
        const collectionName = await watchFolderService.getCollectionName(
            filePath
        );

        console.log('added (trash) to event queue', collectionName, filePath);

        if (!collectionName) {
            return;
        }

        const event: EventQueueItem = {
            type: 'trash',
            collectionName,
            paths: [filePath],
        };
        watchFolderService.pushEvent(event);
    } catch (e) {
        logError(e, 'error while calling diskFileRemovedCallback');
    }
}

export async function diskFolderRemovedCallback(folderPath: string) {
    try {
        const collectionName = await watchFolderService.getCollectionName(
            folderPath
        );
        if (!collectionName) {
            return;
        }

        if (hasMappingSameFolderPath(collectionName, folderPath)) {
            watchFolderService.pushTrashedDir(folderPath);
        }
    } catch (e) {
        logError(e, 'error while calling diskFolderRemovedCallback');
    }
}

const hasMappingSameFolderPath = (
    collectionName: string,
    folderPath: string
) => {
    const mappings = watchFolderService.getWatchMappings();
    const mapping = mappings.find(
        (mapping) => mapping.collectionName === collectionName
    );
    return mapping.folderPath === folderPath;
};
