export interface JourneyPoint {
    lat: number;
    lng: number;
    name: string;
    country: string;
    /**
     * Millisecond sort/display key in the local photo timeline.
     *
     * This is not an absolute UTC timestamp.
     */
    timestamp: number;
    image: string;
    fileId: number;
}
