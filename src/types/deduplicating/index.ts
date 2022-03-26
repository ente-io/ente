export interface DeduplicateContextType {
    clubByTime: boolean;
    setClubByTime: (clubByTime: boolean) => void;
    fileSizeMap: Map<number, number>;
    state: boolean;
}
