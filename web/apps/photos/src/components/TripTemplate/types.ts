import { type Collection } from "ente-media/collection";
import { type EnteFile } from "ente-media/file";

export interface JourneyPoint {
    lat: number;
    lng: number;
    name: string;
    country: string;
    timestamp: string;
    image: string;
    fileId: number;
}

export interface GeocodingResponse {
    features?: {
        properties?: {
            locality?: string;
            neighbourhood?: string;
            county?: string;
            region?: string;
            name?: string;
            country?: string;
        };
    }[];
}

export interface TripTemplateProps {
    files: EnteFile[];
    collection?: Collection;
    albumTitle?: string;
    user?: { id: number; email: string; token: string; [key: string]: unknown };
    enableDownload?: boolean;
    onSetOpenFileViewer?: (open: boolean) => void;
    onRemotePull?: () => Promise<void>;
    onAddPhotos?: () => void;
}