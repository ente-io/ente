import { CITIES_URL } from '@ente/shared/constants/urls';
import { LocationTagData } from 'types/entity';
import { Location } from 'types/upload';

export interface City {
    city: string;
    country: string;
    lat: number;
    lng: number;
}

const DEFAULT_CITY_RADIUS = 10;

class LocationSearchService {
    private cities: Array<City> = [];
    private citiesPromise: Promise<void>;

    loadCities() {
        if (this.citiesPromise) {
            return;
        }
        // TODO: Ensure the response is cached on the client
        this.citiesPromise = fetch(CITIES_URL).then((response) => {
            return response.json().then((data) => {
                this.cities = data['data'];
            });
        });
    }

    async searchCities(searchTerm: string) {
        if (!this.citiesPromise) {
            this.loadCities();
        }
        await this.citiesPromise;
        return this.cities.filter((city) => {
            return city.city.toLowerCase().includes(searchTerm.toLowerCase());
        });
    }
}

export default new LocationSearchService();

export function isInsideLocationTag(
    location: Location,
    locationTag: LocationTagData
) {
    const { centerPoint, aSquare, bSquare } = locationTag;
    const { latitude, longitude } = location;
    const x = Math.abs(centerPoint.latitude - latitude);
    const y = Math.abs(centerPoint.longitude - longitude);
    if ((x * x) / aSquare + (y * y) / bSquare <= 1) {
        return true;
    } else {
        return false;
    }
}

// TODO: Verify correctness
export function isInsideCity(location: Location, city: City) {
    const { lat, lng } = city;
    const { latitude, longitude } = location;
    const x = Math.abs(lat - latitude);
    const y = Math.abs(lng - longitude);
    if (x * x + y * y <= DEFAULT_CITY_RADIUS * DEFAULT_CITY_RADIUS) {
        return true;
    } else {
        return false;
    }
}
