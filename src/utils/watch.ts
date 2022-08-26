import { Mapping } from '../types';

export function isMappingPresent(watchMappings: Mapping[], folderPath: string) {
    const watchMapping = watchMappings?.find(
        (mapping) => mapping.folderPath === folderPath
    );
    return !!watchMapping;
}
