import { useEffect } from 'react';
import { styled } from '@mui/material';
import { runningInBrowser } from 'utils/common';

import 'leaflet/dist/leaflet.css';
import 'leaflet-defaulticon-compatibility/dist/leaflet-defaulticon-compatibility.webpack.css'; // Re-uses images from ~leaflet package
runningInBrowser() && require('leaflet-defaulticon-compatibility');

const LAYER_TILE_URL = 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
const LAYER_TILE_ATTRIBUTION =
    '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors';
const MAP_CONTAINER_ID = 'map-container';
const ZOOM_LEVEL = 16;

const MapBoxContainer = styled('div')`
    height: 200px;
    width: 100%;
`;

interface MapBoxProps {
    location: { latitude: number; longitude: number };
}

const MapBox: React.FC<MapBoxProps> = ({ location }) => {
    useEffect(() => {
        const main = async () => {
            const L = await import('leaflet');
            const position: L.LatLngTuple = [
                location.latitude,
                location.longitude,
            ];
            const mapContainer = document.getElementById(MAP_CONTAINER_ID);

            if (mapContainer && !mapContainer.hasChildNodes()) {
                const map = L.map(mapContainer).setView(position, ZOOM_LEVEL);
                L.tileLayer(LAYER_TILE_URL, {
                    attribution: LAYER_TILE_ATTRIBUTION,
                }).addTo(map);
                L.marker(position).addTo(map).openPopup();
            }
        };
        main();
    }, []);

    return <MapBoxContainer id={MAP_CONTAINER_ID} />;
};

export default MapBox;
