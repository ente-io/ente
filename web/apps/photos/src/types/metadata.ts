export interface Location {
    latitude: number;
    longitude: number;
}

export interface ParsedExtractedMetadata {
    location: Location;
    creationTime: number;
    width: number;
    height: number;
}
