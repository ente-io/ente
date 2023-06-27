import { useEffect } from 'react';
import dynamic from 'next/dynamic';
import { runningInBrowser } from 'utils/common';
import 'leaflet/dist/leaflet.css';
import 'leaflet-defaulticon-compatibility/dist/leaflet-defaulticon-compatibility.webpack.css'; // Re-uses images from ~leaflet package
import * as L from 'leaflet';
runningInBrowser() ? require('leaflet-defaulticon-compatibility') : null;

const LAYER_TILE_URL = 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
const LAYER_TILE_ATTRIBUTION =
    '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors';
const MAP_CONTAINER_ID = 'map-container';
const ZOOM_LEVEL = 16;

interface MapBoxProps {
    location: { latitude: number; longitude: number };
}

const MapBox: React.FC<MapBoxProps> = ({ location }) => {
    useEffect(() => {
        const position: L.LatLngTuple = [location.latitude, location.longitude];
        const mapContainer = document.getElementById(MAP_CONTAINER_ID);

        if (mapContainer && !mapContainer.hasChildNodes()) {
            const map = L.map(mapContainer).setView(position, ZOOM_LEVEL);
            L.tileLayer(LAYER_TILE_URL, {
                attribution: LAYER_TILE_ATTRIBUTION,
            }).addTo(map);
            L.marker(position).addTo(map).openPopup();
        }
    }, []);

    return (
        <div
            id={MAP_CONTAINER_ID}
            style={{ height: '200px', width: '100%' }}></div>
    );
};

export default dynamic(() => Promise.resolve(MapBox), { ssr: false });
