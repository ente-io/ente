import { CITIES_URL } from '@ente/shared/constants/urls';

interface City {
    city: string;
    country: string;
    lat: number;
    lng: number;
}

class LocationSearchService {
    private cities: Array<City> = [];

    loadCities() {
        fetch(CITIES_URL).then((response) => {
            response.json().then((data) => {
                this.cities = data;
                console.log(this.cities);
            });
        });
    }
}

export default new LocationSearchService();
