export type DeduplicateContextType = {
    clubSameTimeFilesOnly: boolean;
    setClubSameTimeFilesOnly: (clubSameTimeFilesOnly: boolean) => void;
    fileSizeMap: Map<number, number>;
    isOnDeduplicatePage: boolean;
};

export const DefaultDeduplicateContext = {
    clubSameTimeFilesOnly: false,
    setClubSameTimeFilesOnly: () => null,
    fileSizeMap: new Map<number, number>(),
    isOnDeduplicatePage: false,
};
