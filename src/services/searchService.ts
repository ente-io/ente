import HTTPService from './HTTPService';
import * as chrono from 'chrono-node';
import { getEndpoint } from 'utils/common/apiUtil';

const ENDPOINT = getEndpoint();

export type Bbox = [number, number, number, number];
export interface LocationSearchResponse {
    place: string;
    bbox: Bbox;
}
export const getMapboxToken = () => {
    return process.env.NEXT_PUBLIC_MAPBOX_TOKEN;
};

export function parseHumanDate(humanDate: string) {
    return chrono.parseDate(humanDate);
}

export async function searchLocation(
    searchPhrase: string
): Promise<LocationSearchResponse[]> {
    const resp = await HTTPService.get(`${ENDPOINT}/search/location`, {
        query: searchPhrase,
        limit: 4,
    });
    return resp.data.result;
}
