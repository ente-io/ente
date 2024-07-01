export interface Location {
    latitude: number | null;
    longitude: number | null;
}

export interface ParsedExtractedMetadata {
    location: Location;
    creationTime: number;
    width: number;
    height: number;
}
