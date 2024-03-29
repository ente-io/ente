import { WatchMapping } from "../types/ipc";

export function isMappingPresent(
    watchMappings: WatchMapping[],
    folderPath: string,
) {
    const watchMapping = watchMappings?.find(
        (mapping) => mapping.folderPath === folderPath,
    );
    return !!watchMapping;
}
