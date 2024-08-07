import log from "@/base/log";
import type { Location, LocationTagData } from "types/entity";

export interface City {
    city: string;
    country: string;
    lat: number;
    lng: number;
}

const DEFAULT_CITY_RADIUS = 10;
const KMS_PER_DEGREE = 111.16;

class LocationSearchService {
    private cities: Array<City> = [];
    private citiesPromise: Promise<void>;

    async loadCities() {
        try {
            if (this.citiesPromise) {
                return;
            }
            this.citiesPromise = fetch(
                "https://static.ente.io/world_cities.json",
            ).then((response) => {
                return response.json().then((data) => {
                    this.cities = data["data"];
                });
            });
            await this.citiesPromise;
        } catch (e) {
            log.error("LocationSearchService loadCities failed", e);
            this.citiesPromise = null;
        }
    }

    async searchCities(searchTerm: string) {
        try {
            if (!this.citiesPromise) {
                this.loadCities();
            }
            await this.citiesPromise;
            return this.cities.filter((city) => {
                return city.city
                    .toLowerCase()
                    .startsWith(searchTerm.toLowerCase());
            });
        } catch (e) {
            log.error("LocationSearchService searchCities failed", e);
            throw e;
        }
    }
}

export default new LocationSearchService();

export function isInsideLocationTag(
    location: Location,
    locationTag: LocationTagData,
) {
    return isLocationCloseToPoint(
        location,
        locationTag.centerPoint,
        locationTag.radius,
    );
}

export function isInsideCity(location: Location, city: City) {
    return isLocationCloseToPoint(
        { latitude: city.lat, longitude: city.lng },
        location,
        DEFAULT_CITY_RADIUS,
    );
}

function isLocationCloseToPoint(
    centerPoint: Location,
    location: Location,
    radius: number,
) {
    const a = (radius * _scaleFactor(centerPoint.latitude)) / KMS_PER_DEGREE;
    const b = radius / KMS_PER_DEGREE;
    const x = centerPoint.latitude - location.latitude;
    const y = centerPoint.longitude - location.longitude;
    if ((x * x) / (a * a) + (y * y) / (b * b) <= 1) {
        return true;
    }
    return false;
}

///The area bounded by the location tag becomes more elliptical with increase
///in the magnitude of the latitude on the caritesian plane. When latitude is
///0 degrees, the ellipse is a circle with a = b = r. When latitude incrases,
///the major axis (a) has to be scaled by the secant of the latitude.
function _scaleFactor(lat: number) {
    return 1 / Math.cos(lat * (Math.PI / 180));
}
