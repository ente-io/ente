interface GeocodingResponse {
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

// Icon cache to avoid recreating identical icons
export const iconCache = new Map<string, import("leaflet").DivIcon>();

// Throttle function for performance optimization
export const throttle = <T extends (...args: unknown[]) => void>(
    func: T,
    delay: number,
): ((...args: Parameters<T>) => void) => {
    let timeoutId: NodeJS.Timeout | null = null;
    let lastExecTime = 0;

    return (...args: Parameters<T>) => {
        const currentTime = Date.now();

        if (currentTime - lastExecTime > delay) {
            func(...args);
            lastExecTime = currentTime;
        } else {
            if (timeoutId) clearTimeout(timeoutId);
            timeoutId = setTimeout(
                () => {
                    func(...args);
                    lastExecTime = Date.now();
                },
                delay - (currentTime - lastExecTime),
            );
        }
    };
};

// Reverse geocoding function using Stadia Maps
export const getLocationName = async (
    lat: number,
    lng: number,
): Promise<{ place: string; country: string }> => {
    try {
        // Round coordinates to 1 decimal place for geocoding
        const roundedLat = Math.round(lat * 10) / 10;
        const roundedLng = Math.round(lng * 10) / 10;

        const response = await fetch(
            `https://api.stadiamaps.com/geocoding/v1/reverse?point.lat=${roundedLat}&point.lon=${roundedLng}`,
        );

        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        const data = (await response.json()) as GeocodingResponse;

        // Extract location name from the response
        const feature = data.features?.[0];
        let result: { place: string; country: string };

        if (feature?.properties) {
            const props = feature.properties;

            // Build location name with city and state/region for better context
            const city = props.locality || props.neighbourhood;

            // Get location name
            const locationName =
                city || props.county || props.region || props.name || "Unknown";

            // Get country info
            const country = props.country || "Unknown";

            result = { place: locationName, country: country };
        } else {
            // Fallback if no location found
            result = { place: "Unknown", country: "Unknown" };
        }

        return result;
    } catch {
        // Fallback on error
        return { place: "Unknown", country: "Unknown" };
    }
};
