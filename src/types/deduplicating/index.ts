export interface DeduplicateContextType {
    clubSameTimeFilesOnly: boolean;
    setClubSameTimeFilesOnly: (clubSameTimeFilesOnly: boolean) => void;
    fileSizeMap: Map<number, number>;
    state: boolean;
}
