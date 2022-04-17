import { Collection } from 'types/collection';
import { EnteFile } from 'types/file';

export type DeduplicateContextType = {
    clubSameTimeFilesOnly: boolean;
    setClubSameTimeFilesOnly: (clubSameTimeFilesOnly: boolean) => void;
    fileSizeMap: Map<number, number>;
    isOnDeduplicatePage: boolean;
    files: EnteFile[];
    collections: Collection[];
};

export const DefaultDeduplicateContext = {
    clubSameTimeFilesOnly: false,
    setClubSameTimeFilesOnly: () => null,
    fileSizeMap: new Map<number, number>(),
    isOnDeduplicatePage: false,
    files: [],
    collections: [],
};
