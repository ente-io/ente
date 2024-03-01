export type DeduplicateContextType = {
    isOnDeduplicatePage: boolean;
    collectionNameMap: Map<number, string>;
};

export const DefaultDeduplicateContext = {
    clubSameTimeFilesOnly: false,
    setClubSameTimeFilesOnly: () => null,
    fileSizeMap: new Map<number, number>(),
    isOnDeduplicatePage: false,
    collectionNameMap: new Map<number, string>(),
};
