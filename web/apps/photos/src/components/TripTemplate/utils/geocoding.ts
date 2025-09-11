import L from "leaflet";

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

// Geocoding cache to avoid repeated API calls
export const geocodingCache = new Map<
    string,
    { place: string; country: string }
>();

// Icon cache to avoid recreating identical icons
export const iconCache = new Map<string, L.DivIcon>();

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

// Reverse geocoding function using Stadia Maps with caching
// Works without API key for localhost development
export const getLocationName = async (
    lat: number,
    lng: number,
    photoIndex?: number,
): Promise<{ place: string; country: string }> => {
    // Round coordinates to 3 decimal places for cache key (~100m precision)
    const roundedLat = Math.round(lat * 1000) / 1000;
    const roundedLng = Math.round(lng * 1000) / 1000;
    const cacheKey = `${roundedLat},${roundedLng}`;

    // Check cache first
    const cached = geocodingCache.get(cacheKey);
    if (cached) {
        return cached;
    }

    try {
        const response = await fetch(
            `https://api.stadiamaps.com/geocoding/v1/reverse?point.lat=${lat}&point.lon=${lng}`,
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
            result = {
                place: photoIndex
                    ? `Location ${photoIndex}`
                    : `Location ${lat.toFixed(2)}, ${lng.toFixed(2)}`,
                country: "Unknown",
            };
        }

        // Cache the result
        geocodingCache.set(cacheKey, result);
        return result;
    } catch {
        // Fallback on error
        const fallbackResult = {
            place: photoIndex ? `Location ${photoIndex}` : `Unknown Location`,
            country: "Unknown",
        };
        // Cache the fallback to avoid repeated failures
        geocodingCache.set(cacheKey, fallbackResult);
        return fallbackResult;
    }
};
