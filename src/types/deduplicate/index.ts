export type DeduplicateContextType = {
    clubSameTimeFilesOnly: boolean;
    setClubSameTimeFilesOnly: (clubSameTimeFilesOnly: boolean) => void;
    clubSameFileHashesOnly: boolean;
    setClubSameFileHashesOnly: (clubSameFileHashes: boolean) => void;
    fileSizeMap: Map<number, number>;
    isOnDeduplicatePage: boolean;
    collectionNameMap: Map<number, string>;
};

export const DefaultDeduplicateContext = {
    clubSameTimeFilesOnly: false,
    setClubSameTimeFilesOnly: () => null,
    clubSameFileHashesOnly: false,
    setClubSameFileHashesOnly: () => null,
    fileSizeMap: new Map<number, number>(),
    isOnDeduplicatePage: false,
    collectionNameMap: new Map<number, string>(),
};
