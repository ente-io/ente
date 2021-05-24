import HTTPService from './HTTPService';
import * as chrono from 'chrono-node';

const KM_IN_DEGREE = 0.01;
export type Bbox = [number, number, number, number];
export interface LocationSearchResponse {
    placeName: string;
    bbox: Bbox;
}
export const getMapboxToken = () => {
    console.log(
        process.env.NEXT_PUBLIC_MAPBOX_TOKEN,
        process.env.NEXT_PUBLIC_SENTRY_DSN
    );
    return process.env.NEXT_PUBLIC_MAPBOX_TOKEN;
};

export function parseHumanDate(humanDate: string) {
    return chrono.parseDate(humanDate);
}

export async function searchLocation(
    location: string
): Promise<LocationSearchResponse[]> {
    const resp = await HTTPService.get(
        `https://api.mapbox.com/geocoding/v5/mapbox.places/${encodeURI(
            location
        )}.json`,
        { access_token: getMapboxToken(), limit: 4 }
    );

    return resp.data.features.length == 0
        ? new Array<LocationSearchResponse>()
        : resp.data.features.map((feature) => ({
              placeName: feature.place_name,
              bbox:
                  feature.bbox ??
                  ([
                      feature.center[0] - KM_IN_DEGREE,
                      feature.center[1] - KM_IN_DEGREE,
                      feature.center[0] + KM_IN_DEGREE,
                      feature.center[1] + KM_IN_DEGREE,
                  ] as Bbox),
          }));
}
