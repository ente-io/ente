import { nullToUndefined } from "@/utils/transform";

/**
 * A location, represented as a (latitude, longitude) pair.
 */
export interface Location {
    latitude: number;
    longitude: number;
}

/**
 * Convert a pair of nullish latitude and longitude values into a
 * {@link Location} if both of them are present.
 */
export const parseLatLng = (
    latitudeN: number | undefined | null,
    longitudeN: number | undefined | null,
): Location | undefined => {
    const latitude = nullToUndefined(latitudeN);
    const longitude = nullToUndefined(longitudeN);

    if (latitude === undefined || longitude === undefined) return undefined;

    return { latitude, longitude };
};
