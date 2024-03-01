import { ElectronFile } from "types/upload";
import { WatchMapping } from "types/watchFolder";
import { isSystemFile } from "utils/upload";

function isSyncedOrIgnoredFile(file: ElectronFile, mapping: WatchMapping) {
    return (
        mapping.ignoredFiles.includes(file.path) ||
        mapping.syncedFiles.find((f) => f.path === file.path)
    );
}

export function getValidFilesToUpload(
    files: ElectronFile[],
    mapping: WatchMapping,
) {
    const uniqueFilePaths = new Set<string>();
    return files.filter((file) => {
        if (!isSystemFile(file) && !isSyncedOrIgnoredFile(file, mapping)) {
            if (!uniqueFilePaths.has(file.path)) {
                uniqueFilePaths.add(file.path);
                return true;
            }
        }
        return false;
    });
}
