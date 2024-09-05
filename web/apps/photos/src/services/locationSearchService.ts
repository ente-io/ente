import log from "@/base/log";
import type { City } from "@/new/photos/services/search/types";

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
