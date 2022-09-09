import { ElectronFile } from 'types/upload';
import { WatchMapping } from 'types/watchFolder';
import { isSystemFile } from 'utils/upload';

export function isNotSyncedOrIgnoredFile(
    file: ElectronFile,
    mapping: WatchMapping
) {
    return (
        !mapping.ignoredFiles.includes(file.path) &&
        !mapping.syncedFiles.find((f) => f.path === file.path)
    );
}

export function getValidFilesToUpload(
    files: ElectronFile[],
    mapping: WatchMapping
) {
    const uniqueFilePaths = new Set<string>();
    return files.filter(
        (file) =>
            !isSystemFile(file) &&
            !isNotSyncedOrIgnoredFile(file, mapping) &&
            !uniqueFilePaths.has(file.path)
    );
}
