import log from "@/next/log";
import { ElectronFile } from "types/upload";
import { EventQueueItem } from "types/watchFolder";
import watchFolderService from "./watchFolderService";

export async function diskFileAddedCallback(file: ElectronFile) {
    try {
        const collectionNameAndFolderPath =
            await watchFolderService.getCollectionNameAndFolderPath(file.path);

        if (!collectionNameAndFolderPath) {
            return;
        }

        const { collectionName, folderPath } = collectionNameAndFolderPath;

        const event: EventQueueItem = {
            type: "upload",
            collectionName,
            folderPath,
            files: [file],
        };
        watchFolderService.pushEvent(event);
        log.info(
            `added (upload) to event queue, collectionName:${event.collectionName} folderPath:${event.folderPath}, filesCount: ${event.files.length}`,
        );
    } catch (e) {
        log.error("error while calling diskFileAddedCallback", e);
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
            type: "trash",
            collectionName,
            folderPath,
            paths: [filePath],
        };
        watchFolderService.pushEvent(event);
        log.info(
            `added (trash) to event queue collectionName:${event.collectionName} folderPath:${event.folderPath} , pathsCount: ${event.paths.length}`,
        );
    } catch (e) {
        log.error("error while calling diskFileRemovedCallback", e);
    }
}

export async function diskFolderRemovedCallback(folderPath: string) {
    try {
        const mappings = await watchFolderService.getWatchMappings();
        const mapping = mappings.find(
            (mapping) => mapping.folderPath === folderPath,
        );
        if (!mapping) {
            log.info(`folder not found in mappings, ${folderPath}`);
            throw Error(`Watch mapping not found`);
        }
        watchFolderService.pushTrashedDir(folderPath);
        log.info(`added trashedDir, ${folderPath}`);
    } catch (e) {
        log.error("error while calling diskFolderRemovedCallback", e);
    }
}
